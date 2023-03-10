require "jekyll"
require "jekyll-shields_io"
require "httparty"
require "nokogiri"
require "spec_helper"

RSpec.describe "Liquid::Template" do
  it "has 'shields_io' tag" do
    expect(Liquid::Template.tags["shields_io"]).to be Jekyll::ShieldsIO::ShieldsIOTag
  end
end

class ShieldFactoryForTest < Jekyll::ShieldsIO::ShieldFactory
  # Jekyll's Site object
  # @return [Jekyll::Site]
  attr_reader :site
end

class ShieldsIOTagForTest < Jekyll::ShieldsIO::ShieldsIOTag
  attr_reader :factory
end

RSpec.describe Jekyll::ShieldsIO::StaticShieldFile.name do
  describe "destination" do
    before do
      site = Jekyll::Site.new(Jekyll.configuration({"source" => Jekyll::Configuration::DEFAULTS[:source], "skip_config_files" => true}))
      @dest = File.join("_cache", "shields_io")
      @basename = "basename.svg"
      @shield_file = Jekyll::ShieldsIO::StaticShieldFile.new site, site.source, File.join("_cache", "shields_io"), @basename, @dest
    end
    it "can output expected destination" do
      dest = @shield_file.destination "dest_folder"
      expect(dest).to eq File.join("dest_folder", @dest, @basename)
    end
  end
end

RSpec.describe Jekyll::ShieldsIO::ShieldFactory.name do
  before do
    # Mocked configuration values
    @context = Liquid::Context.new({}, {}, {
      site: Jekyll::Site.new(Jekyll.configuration({"source" => "", "skip_config_files" => true}))
    })
    @factory = ShieldFactoryForTest.new @context
    File.open("spec/support/test_shield.svg", "r") { |fp|
      @test_shield = fp.read
    }
    if @test_shield.nil?
      fail "Test code has failed to read the support file for sample shield file"
    end
    @config = {
      message: "Right-side text",
      label: "Left-side text",
      color: "777777",
      style: "plastic"
    }
    @query = @factory.send(:hash_to_query, @config, [:href, :alt, :class])
    @cache_dir = @factory.send :cache_dir
  end

  describe "get_shield" do
    context "when the given shield configuration yields new url" do
      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, body: @test_shield, code: 200)
        )
      end

      it "can fetch and extract new shields" do
        result = @factory.get_shield @config
        match_with_sample_properties result
      end
    end

    context "when the given shield configuration yields known (cached) url" do
      before do
        # In this test, we deliberately mock a crash response;
        # if the plugin misses the cache and tries to pull the shield, the plugin will crash.
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, body: "This should not happen", code: 500)
        )

        if @test_shield.nil?
          fail "Test code has failed to read the support file for sample shield file"
        end
        FileUtils.mkdir_p @cache_dir
        File.write(File.join(@cache_dir, "#{Digest::MD5.hexdigest @query}.svg"), @test_shield)
      end

      it "can pull cache for existing shields" do
        result = nil
        expect {
          result = @factory.get_shield @config
        }.not_to raise_error
        match_with_sample_properties result
      end
    end

    private

    # @param [Jekyll::ShieldsIO::Shield, nil] result
    # noinspection RubyNilAnalysis
    def match_with_sample_properties(result)
      expect(result).not_to be_nil
      expect(result.width).to eq 174
      expect(result.height).to eq 18
      expect(result.href).to be_nil
      expect(result.alt).to be_nil
      expect(result.cls).to be_nil
      expect(result.path).to eq File.join(@factory.send(:cache_dir), "#{Digest::MD5.hexdigest @query}.svg")
      expect(result.basename).to eq "#{Digest::MD5.hexdigest @query}.svg"
    end
  end

  describe "queue_shield" do
    before do
      allow(HTTParty).to receive(:get).and_return(
        instance_double(HTTParty::Response, body: @test_shield, code: 200)
      )
    end

    context "when queueing a shield for deployment" do
      it "can queue Shield object into Jekyll's static files as StaticShieldFile" do
        shield = @factory.get_shield @config
        @factory.queue_shield shield
        check_queue_property shield
      end
    end

    context "when shields of the same property gets queued" do
      it "queues such shields exactly once" do
        shield = @factory.get_shield @config
        # Notice that we're calling these over and over again
        @factory.queue_shield shield
        @factory.queue_shield shield
        @factory.queue_shield shield
        check_queue_property shield
      end
    end

    private

    def check_queue_property(shield)
      site = @factory.site
      expect(site.static_files).to have_attributes(size: 1)
      expect(site.static_files.any? { |f|
        f.relative_path == File.join("_cache", "shields_io", shield.basename)
      }).to eq true
      expect(site.static_files[0].instance_of?(Jekyll::ShieldsIO::StaticShieldFile)).to eq true
    end

    public

    after do
      @factory.site.static_files.clear
    end
  end

  after do
    # The factory creates cache dir automatically, so we remove it for future tests
    if File.exist? @cache_dir
      FileUtils.rm_r @cache_dir
    end
  end
end

RSpec.describe Jekyll::ShieldsIO::ShieldsIOTag.name do
  before do
    @context = Liquid::Context.new({}, {}, {
      site: Jekyll::Site.new(Jekyll.configuration({"source" => "", "skip_config_files" => true}))
    })
    File.open("spec/support/test_shield.svg", "r") { |fp|
      @test_shield = fp.read
    }
    if @test_shield.nil?
      fail "Test code has failed to read the support file for sample shield file"
    end
    @tokenizer = Liquid::Tokenizer.new("")
    @parse_context = Liquid::ParseContext.new
  end
  describe "#render" do
    context "Normal situations" do
      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, body: @test_shield, code: 200)
        )
      end
      context "When alt is supplied" do
        before do
          markup = '{"message": "test", "alt": "Alternative Text"}'
          @tag = ShieldsIOTagForTest.parse(nil, markup, @tokenizer, @parse_context)
        end
        it "creates an image tag with alt attribute" do
          rendered = @tag.render @context
          dom = Nokogiri::HTML.parse(rendered, nil, "utf-8")
          expect(dom.xpath("//img/@alt").inner_text).to eq "Alternative Text"
        end
      end
      context "When href is supplied" do
        before do
          markup = '{"message": "test", "href": "https://example.com/"}'
          @tag = ShieldsIOTagForTest.parse(nil, markup, @tokenizer, @parse_context)
        end
        it "encloses the image tag within an <a> tag, making it a link" do
          rendered = @tag.render @context
          dom = Nokogiri::HTML.parse(rendered, nil, "utf-8")
          expect(dom.xpath("//a/@href").inner_text).to eq "https://example.com/"
        end
      end
    end

    context "Abnormal situations" do
      context "When plugin fails to fetch new shield" do
        before do
          allow(HTTParty).to receive(:get).and_return(
            instance_double(HTTParty::Response, body: "500 Service Unavailable", code: 500)
          )
        end
        it "outputs last-ditch effort alternative text" do
          markup = '{"message": "test"}'
          @tag = ShieldsIOTagForTest.parse(nil, markup, @tokenizer, @parse_context)
          rendered = @tag.render @context
          expect(rendered).to eq "<p> test</p>"
        end
      end
    end

    after do
      dir = @tag.factory.send :cache_dir
      if File.exist? dir
        FileUtils.rm_r @tag.factory.send :cache_dir
      end
    end
  end
end

Liquid::Template.register_tag("shield_io", Jekyll::ShieldsIO::ShieldsIOTag)

RSpec.describe "Integration test" do
  before do
    # Mocked configuration values
    @context = Liquid::Context.new({}, {}, {
      site: Jekyll::Site.new(Jekyll.configuration({"source" => "", "skip_config_files" => true}))
    })
    @factory = Jekyll::ShieldsIO::ShieldFactory.new @context
    @cache_dir = @factory.send :cache_dir
  end

  context "When valid JSON is passed" do
    it "can render a shield" do
      t = Liquid::Template.new
      t.parse(
        <<~EOT
          {% shield_io {
          "message": "test"
          } %}
      EOT
      )
      expect(t.render(@context)).not_to include("Liquid error: internal")
    end
  end

  context "When invalid JSON is passed" do
    it "fails with exception" do
      t = Liquid::Template.new
      expect {
        t.parse(
          <<~EOT
            {% shield_io {this is invalid!} %}
        EOT
        )
      }.to raise_error Jekyll::ShieldsIO::ShieldConfigMalformedError
    end
  end

  after do
    if File.exist? @cache_dir
      FileUtils.rm_r @cache_dir
    end
  end
end
