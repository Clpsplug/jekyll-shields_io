lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "jekyll-shields_io/version"

Gem::Specification.new do |s|
  s.name = "jekyll-shields_io"
  s.version = Jekyll::ShieldsIO::VERSION
  s.summary = "Adds ability to put shields.io badges in your Jekyll blog"
  s.description = <<~EOD
    This Jekyll plugin allows you to add a shields.io badge in your blog
    without forming very long URLs - instead, the properties are set via JSON.
  EOD
  s.authors = ["C. Plug"]
  s.email = "hsp.tosh.5200113@gmail.com"
  s.license = "MIT"

  s.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.require_paths = ["lib"]
  s.add_dependency "jekyll", ">= 3.5", "< 5.0"
  s.add_dependency "nokogiri", "~> 1.4", "< 2.0"
  s.add_dependency "httparty", "~> 0.17", "< 1.0"
end
