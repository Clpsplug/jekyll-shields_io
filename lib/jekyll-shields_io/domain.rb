module Jekyll
  module ShieldsIO
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

    # Thrown when the plugin fails to fetch the shield image.
    class ShieldFetchError < StandardError
    end

    # Thrown when the plugin fails to access the cached shield file.
    # Realistically, if this happens something must be very wrong with the disk the cache is written to
    # because the plugin would've crashed with IO errors well before this is thrown.
    class ShieldFileError < StandardError
    end
  end
end
