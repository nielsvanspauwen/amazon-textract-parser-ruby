# Amazon Textract Results Parser

This is a quick Ruby port of [https://github.com/mludvig/amazon-textract-parser](https://github.com/mludvig/amazon-textract-parser)

It's useful for interpreting the result of Amazon Textract info.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'amazon-textract-parser-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install amazon-textract-parser-ruby

## Usage

```ruby
textract = Aws::Textract::Client.new
textract.start_document_analysis({...})
response = textract.get_document_analysis({...})
doc = AmazonTRP::Document.new(response.to_h)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

For more info on creating and maintaining gems, check https://bundler.io/v2.0/guides/creating_gem.html

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nielsvanspauwen/amazon-textract-parser-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
