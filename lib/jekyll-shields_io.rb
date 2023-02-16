require "digest"
require "fileutils"
require "json"
require "nokogiri"
require "httparty"

module Jekyll
  module ShieldsIO
    # Factory for generating Shields.IO's shield
    class ShieldFactory
      # @param [Liquid::Context] context
      def initialize(context)
        # @type [Jekyll::Site]
        @site = context.registers[:site]
        # @type [String]
        @source_dir = context.registers[:site].config["source"]
      end

      # @param [Hash] config
      def get_shield(config)
        href = config[:href]
        alt = config[:alt]
        cls = config[:class]
        query = hash_to_query(config, [:href, :alt, :class])

        unless File.exist? cache_dir
          FileUtils.mkdir_p cache_dir
          log "Cache directory was made for Shields.IO tags."
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
          unless response.code == 200
            warn "Shields.io refused our request with Response Code #{response.code}."
            return nil
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
      #
      # shield - Shield to queue for this Jekyll site's Jekyll::StaticFile.
      def queue_shield(shield)
        unless File.exist? shield.path
          warn "Cached shield image file was not found, maybe we failed to fetch it?"
          return
        end
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
        (@source_dir.nil? || @source_dir.empty?) ?
          File.join(Dir.pwd, "_cache", "shields_io") :
          File.join(Dir.pwd, @source_dir, "_cache", "shields_io")
      end

      def hash_to_query(config, ignored_symbols)
        c = config.clone
        # Keys must be taken out from the clone because Jekyll seems to cache exact same calls to tags?
        ignored_symbols.each { |s| c.delete(s) }
        c.to_a.map { |k, v|
          "#{k}=#{v}"
        }.join "&"
      end

      def log(mes)
        unless @site.config["verbose"] != true
          warn mes
        end
      end
    end

    # Object to represent the Shields.IO shield (plus some extra stuff)
    class Shield
      # To be used for img tag.
      # @return [Integer]
      attr_reader :width
      # To be used for img tag.
      # @return [Integer]
      attr_reader :height
      # If not nil, make the shield image a link.
      # @return [String]
      attr_reader :href
      # Alternative string for this shield, should the browser fails to load the image
      # @return [String]
      attr_reader :alt
      # HTML class for this shield image.
      # @return [String]
      attr_reader :cls
      # Path to the cache file. *Not* to be used for HTML - use :basename instead.
      # @return [String]
      attr_reader :path
      # Basename of the shield.
      # Specifying "assets/img/shields/" + :basename to src attribute should display this shield.
      # @return [String]
      attr_reader :basename

      def initialize(width, height, path, href, alt, cls)
        @width = width
        @height = height
        @path = path
        @basename = File.basename path
        @href = href
        @alt = alt
        @cls = cls
      end
    end

    # Jekyll representation for the cached shield SVG files.
    class StaticShieldFile < Jekyll::StaticFile
      attr_reader :name

      # Initialize a new CachedShield.
      # site - The Site.
      # base - The String path to the <source>.
      # dir  - The String path between <source> and the file.
      # name - The String filename of the file.
      # dest - The String destination path override.
      def initialize(site, base, dir, name, dest)
        super site, base, dir, name
        @name = name
        @dest = dest
      end

      def destination(dest)
        File.join dest, @dest, @name
      end
    end

    class ShieldError < StandardError
      def initialize(msg = "Failed to fetch the shield.")
        super
      end
    end

    # Jekyll Liquid Tag for Shields.io
    #
    # Usage: {% shields_io <query param + special param as json> %}
    class ShieldsIOTag < Liquid::Tag
      def initialize(tag_name, input, parse_context)
        super
        # @type [Hash]
        @payload = JSON.parse(input.strip, {symbolize_names: true})
      end

      def render(context)
        fct = ShieldFactory.new context
        shield = fct.get_shield @payload
        if shield.nil?
          raise ShieldError.new
        end
        fct.queue_shield shield

        shield_tag = <<HTML
      <img src="/#{fct.target_dir}/#{shield.basename}" width="#{shield.width}" height="#{shield.height}"
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
      end
    end
  end
end

Liquid::Template.register_tag("shields_io", Jekyll::ShieldsIO::ShieldsIOTag)
