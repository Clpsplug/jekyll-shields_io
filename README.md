# jekyll-shields_io

> **Adding shields (badges) to your Jekyll blog, made more readable**

This is a Jekyll plugin to generate a [Shields.io](https://shields.io) badge in your Jekyll blog
with a more readable way.

Shields.io takes the properties of the badges you want to make in forms of GET parameters like so:

https://img.shields.io/static/v1?label=Find%20me%20on&message=GitHub&color=181717&style=flat&logo=github

This URL would become this:
![A badge that says Find me on GitHub](https://img.shields.io/static/v1?label=Find%20me%20on&message=GitHub&color=181717&style=flat&logo=github)

This plugin exists because this URL was too long for me to debug.

Instead, this plugin accepts parameters structured as a JSON:

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

## Installation

```
gem "jekyll-shields_io", git: "https://github.com/clpsplug/jekyll-shields_io", branch: "base"
```

RubyGems TBA

## Features

### Easy to debug shield parameters

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

## NOTE: i18n plugin compatibility

This plugin tries to detect i18n plugin [Polyglot](https://github.com/untra/polyglot) when deploying shields to the assets folder;
this is done so that we don't accidentally deploy the shields for each language version of your site
(because usually you would have one `asset` folder that all the language versions would access.)  

If you use other i18n plugins, the plugin may fail to spot that such i18n plugin is generating non-main language version of the site
and incorrectly deploy cached shields to those versions.  
If you happen to see this behavior, please report it or send me a PR so that we can make this plugin compatible with that one!

## Contributing

Bug reports & pull requests are welcome on [GitHub repo](https://github.com/clpsplug/jekyll-shields_io).

## License

[MIT License](https://opensource.org/licenses/MIT)