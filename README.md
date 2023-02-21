# jekyll-shields_io

> **Adding shields (badges) to your Jekyll blog, made more readable**

![Ruby 2.7 and 3.1 supported](https://img.shields.io/badge/Ruby-2.7%20%7C%203.1-%23CC342D?logo=ruby)
![Jekyll 3.5 through 4.3 supported](https://img.shields.io/badge/Jekyll-3.5%20~%204.x-%23CC0000?logo=jekyll)
![Test status](https://github.com/clpsplug/jekyll-shields_io/actions/workflows/test.yml/badge.svg)

This is a Jekyll plugin to generate a [Shields.io](https://shields.io) badge in your Jekyll blog
with a more readable way.

Shields.io takes the properties of the badges you want to make in forms of GET parameters like so:

https://img.shields.io/static/v1?label=Find%20me%20on&message=GitHub&color=181717&style=flat&logo=github

This URL would become this:
![A badge that says Find me on GitHub](https://img.shields.io/static/v1?label=Find%20me%20on&message=GitHub&color=181717&style=flat&logo=github)

This plugin exists because this URL was too long for me to debug.

Instead, this plugin accepts parameters structured as a JSON:

```liquid
<!-- When using in Markdown, you need to use `{%- tag -%}` syntax - see "Usage" section -->
{% shields_io {
  "label": "Find me on",
  "message": "GitHub",
  "color": "181717",
  "style": "flat",
  "logo": "github",
}
%}
```

## Installation

1. Introduce this gem in your Gemfile
    ```ruby
    group :jekyll_plugins do
      # Latest release
      gem "jekyll-shields_io"
      # "HEAD" version
      gem "jekyll-shields_io", git: "https://github.com/clpsplug/jekyll-shields_io", branch: "base"
    end
    ```
2. `bundle install`
3. Add the plugin to your `_config.yml`
    ```yaml
    plugins:
      - jekyll-shields_io
    ```

## Usage

The tag name is `shields_io`.
The JSON payload for your shield follows the tag name.
You can put newlines in your JSON for readability.

Depending on where you use the tag, you need to use one of the following tag syntaxes:

### Using the tag in Liquid template / HTML
(i.e., the file name is either `*.html` or `*.liquid`)
```liquid
{% shields_io {
  "label": "Find me on",
  "message": "GitHub",
  "color": "181717",
  "style": "flat",
  "logo": "github",
}
%}
```

### Using the tag in Markdown
(i.e., the file name is `*.md`)  
For markdown files, this syntax is required because the other one causes the shields `<img>` tags to be escaped.
```liquid
<!-- Note the "hyphen" (-) after the percentage sign (%) -->
{%- shields_io {
  "label": "Find me on",
  "message": "GitHub",
  "color": "181717",
  "style": "flat",
  "logo": "github",
}
-%}
```

## Supported parameters

| key     | content                                                                                                                                                                                                                                     | required?                    |
|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------|
| message | The right-side text of the shield.                                                                                                                                                                                                          | YES                          |
| alt     | The alternative text for the image. This _should_ be specified for accessibility reasons and when the service fails for any reason.                                                                                                         | NO, but strongly recommended |
| label   | The left-side text of the shield. If left, it will be "static"                                                                                                                                                                              | NO                           |
| color   | The color of the right side (some styles may ignore this value.) This can be color name (see [Shields.io](https://shields.io/) for supported names) or hex color code. Hex color codes _must not_ contain `#`. If left, 'inactive' is used. | NO                           |
| style   | The shield style, see [Shields.io](https://shields.io) for valid values. If left, 'plastic' is used.                                                                                                                                        | NO                           |
| logo    | Service name or Simple Icons icon name; display on the left of the leftside text.                                                                                                                                                           | NO                           |
| href    | A URL. Specifying this key will turn the shield into a clickable link                                                                                                                                                                       | NO                           |

## Features

### Debuggable shield parameters

You can specify the parameters passed to Shields.io using JSON,
which prevents accidental and hard-to-spot mistakes.

### Automatic caching

The shields are only fetched at the first time it is rendered during site builds.  

This plugin creates a `_cache` directory in the blog's source directory
(which is the project root by default, can be configured with `source` config value)
and stores fetched shields, and then deploys them into the blog's `asset/img/shields` folder
to prevent unnecessary external HTML requests.

Deployment is done build-time, so it does not mess with your blog source
(other than creating `_cache` dir).

### Extra parameters for your convenience

#### Make it a link

With the extended parameter `href`, you can instantly turn the shield
into a clickable link.

```liquid
{% shields_io {
  "label": "Find me on",
  "message": "GitHub",
  "color": "181717",
  "style": "flat",
  "logo": "github",
  "href": "https://github.com/clpsplug/jekyll-shields_io"
}
%}
```

#### Alternative Texts

Supplying the image with an alternative text is almost mandatory these days;
this plugin has an extended parameter `alt` for that purpose.

```liquid
{% shields_io {
  "label": "Find me on",
  "message": "GitHub",
  "color": "181717",
  "style": "flat",
  "logo": "github",
  "alt": "Write your alternative text here"
}
%}
```

## NOTE: i18n plugin compatibility

This plugin tries to detect i18n plugin [Polyglot](https://github.com/untra/polyglot) when deploying shields to the assets folder;
this is done so that we don't accidentally deploy the shields for each language version of your site
(because usually you would have one `asset` folder that all the language versions would access.)  

If you use other i18n plugins, the plugin may fail to spot that such i18n plugin is generating non-main language version of the site
and incorrectly deploy cached shields to those versions.  
If you happen to see this behavior, please report it or send me a PR so that we can make this plugin compatible with that one!

## Contributing

Bug reports & pull requests are welcome on [GitHub repo](https://github.com/clpsplug/jekyll-shields_io).

### Development setup

To set up the plugin development env only:
```sh
git clone https://github.com/Clpsplug/jekyll-shields_io.git
# OR
git clone git@github.com:Clpsplug/jekyll-shields_io.git
# OR 
gh repo clone Clpsplug/jekyll-shields_io

# Get dependencies
bundle install
# Run checks that are run on Github Actions
rake
# Run test for latest Jekyll available in your environment
rake spec
# Check code style using "standard" gem
rake standard

# To test every supported Jekyll & Ruby combination:
bundle exec appraisal install
bundle exec appraisal rake spec
```

When contributing, please at least run `rake` and check that 
no issues are raised from "standard" gem and that specs passes!  
(If you're having trouble passing the specs, don't hesitate note so in the PR.)

To test the plugin with real Jekyll environment, 
follow the [Installation](#installation) guide except for adding a line to Gemfile.  
You will need to add this line to your Gemfile instead:
```ruby
gem "jekyll-shields_io", path: "<Wherever you have this repository, can be relative path>"
# for example
gem "jekyll-shields_io", path: "../jekyll-shields_io"
```

## License

[MIT License](https://opensource.org/licenses/MIT)
