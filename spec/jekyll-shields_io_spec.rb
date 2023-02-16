require "jekyll"
require "jekyll-shields_io"
require "httparty"

RSpec.describe "Liquid::Template" do
  it "has 'shields_io' tag" do
    expect(Liquid::Template.tags["shields_io"]).to be Jekyll::ShieldsIO::ShieldsIOTag
  end
end

RSpec.describe "Jekyll::ShieldsIO::ShieldFactory" do
  before do
    # Mocked configuration values
    @context = Liquid::Context.new({}, {}, {
      site: Jekyll::Site.new(Jekyll.configuration({"source" => "", "skip_config_files" => true}))
    })
    @factory = Jekyll::ShieldsIO::ShieldFactory.new @context
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

      after do
        # The factory creates cache dir automatically, so we remove it for future tests
        FileUtils.rm_r @cache_dir
      end
    end

    context "when the given shield configuration yields known (cached) url" do
      before do
        # In this test, we deliberately mock a crash response;
        # if the plugin missed the cache and try to pull the shield, nil will be returned.
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
        result = @factory.get_shield @config
        match_with_sample_properties result
      end

      after do
        FileUtils.rm_r @cache_dir
      end
    end

    private

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

  after do
    FileUtils.rm_r @cache_dir
  end
end
