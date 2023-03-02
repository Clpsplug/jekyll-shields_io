require "digest"
require "fileutils"
require "httparty"
require "jekyll-shields_io/domain"
require "json"
require "nokogiri"

module Jekyll
  module ShieldsIO
    # Factory for generating Shields.IO's shield
    class ShieldFactory
      # @param [Liquid::Context] context
      def initialize(context)
        # @type [Jekyll::Site]
        @site = context.registers[:site]
        # This Jekyll site's "source" config
        # @type [String]
        @source_dir = File.absolute_path context.registers[:site].config["source"], Dir.pwd
      end

      # Fetches the shields from the service or retrieves one from cache
      # @param [Hash] config User-supplied configuration (parsed from JSON)
      # @return [Shield]
      # @raise [ShieldFetchError] If Shields.IO service returns non-200 codes
      def get_shield(config)
        href = config[:href]
        alt = config[:alt]
        cls = config[:class]
        query = hash_to_query(config, [:href, :alt, :class])

        unless File.exist? cache_dir
          FileUtils.mkdir_p cache_dir
          log "Cache directory #{cache_dir} was made for Shields.IO tags."
        end

        cache_file = "#{Digest::MD5.hexdigest query}.svg"
        cache_path = File.join cache_dir, cache_file

        # Consult the cache first
        if File.exist? cache_path
          log "Cache hit for query: #{query} => #{cache_path}"
          # Good news: Shields.IO outputs SVG, which is just XML, and it makes our job very easy!
          image_xml = Nokogiri::XML(File.read(cache_path))
        else
          log "Cache missed for query: #{query}"
          # If the cache does not exist, we need to get the file.
          response = HTTParty.get "https://img.shields.io/static/v1?#{query}"
          unless response.code.div(100) == 2
            raise ShieldFetchError.new "Shields.io refused our request with response code #{response.code}"
          end
          img = response.body
          File.write cache_path, img
          image_xml = Nokogiri::XML(img)
          log "Cached shield for #{query} => #{cache_path}"
        end
        width = image_xml.root["width"].to_i
        height = image_xml.root["height"].to_i
        Shield.new(width, height, cache_path, href, alt, cls)
      end

      # Queue given Shield for this Jekyll site's static files
      # @param [Shield] shield Shield to queue for this Jekyll site's Jekyll::StaticFile.
      # @raise [ShieldFileError] when specified cache file does not exist
      def queue_shield(shield)
        if @site.static_files.select { |f|
          f.is_a? StaticShieldFile
        }.select { |s| s.name == shield.basename }.any?
          log "#{shield.basename} already queued for static files"
          return
        end
        # Polyglot compatibility
        if @site.respond_to?(:active_lang)
          log "Detected Polyglot"
          unless @site.active_lang == @site.default_lang
            log "Skipping copy because of non-default lang site is being built (active lang = #{@site.active_lang})"
            return
          end
        end
        @site.static_files << StaticShieldFile.new(@site, @site.source, File.join("_cache", "shields_io"), shield.basename, target_dir(true))
        log "Cached shield queued for copying"
      end

      def target_dir(for_local = false)
        if for_local
          File.join "assets", "img", "shields"
        end
        "assets/img/shields"
      end

      private

      def cache_dir
        File.join(@source_dir, "_cache", "shields_io")
      end

      def hash_to_query(config, ignored_symbols)
        c = config.clone
        # Keys must be taken out from the clone because Jekyll seems to cache exact same calls to tags?
        ignored_symbols.each { |s| c.delete(s) }
        c.to_a.map { |k, v|
          "#{k}=#{v}"
        }.join "&"
      end

      # Same as warn but will print an identifying tag ([Shields.IO Plugin]) and
      # will not print unless verbose mode is on, or the message is marked important
      # @param [String] mes
      def log(mes)
        if @site.config["verbose"] == true
          warn "[Shields.IO Plugin] #{mes}"
        end
      end
    end

    # Jekyll Liquid Tag for Shields.io
    # Usage: {% shields_io <query param + special param as json> %}
    class ShieldsIOTag < Liquid::Tag
      # @param [String] tag_name == shields_io
      # @param [String] input User input
      # @param [Liquid::Context] parse_context
      def initialize(tag_name, input, parse_context)
        super
        # @type [Hash]
        @payload = JSON.parse(input.strip, {symbolize_names: true})
        # This only appears if there is an error trying to fetch the shield.
        # @type [String]
        @last_ditch_alt = "<p>#{@payload[:label]} #{@payload[:message]}</p>"
      rescue JSON::ParserError => pe
        warn "[Shields.IO Plugin] Shield configuration is malformed (#{pe.message})"
        raise ShieldConfigMalformedError
      end

      def render(context)
        @factory = ShieldFactory.new context
        shield = @factory.get_shield @payload
        @factory.queue_shield shield

        shield_tag = <<~HTML
          <img src="/#{@factory.target_dir}/#{shield.basename}" width="#{shield.width}" height="#{shield.height}"
        HTML
        shield_tag += if !shield.alt.nil?
          " alt=\"#{shield.alt}\" class=\"#{shield.cls}\"/>"
        else
          " class=\"#{shield.cls}\"/>"
        end
        if !shield.href.nil?
          <<~HTML
            <a href="#{shield.href}" class="#{shield.cls}">
            #{shield_tag}
            </a>
          HTML
        else
          shield_tag
        end
      rescue ShieldFetchError
        warn "[Shields.IO Plugin] Failed to fetch shields! (input: #{JSON.dump @payload})"
        @last_ditch_alt
      end
    end
  end
end

Liquid::Template.register_tag("shields_io", Jekyll::ShieldsIO::ShieldsIOTag)
