# Fetch API for Ruby

Ruby's Net::HTTP is very powerful, but has a complicated API. OpenURI is easy to use, but has limited functionality. Third-party HTTP clients each have different APIs, and it can sometimes be difficult to learn how to use them.

There is one HTTP client that we can all use. It is the browser's Fetch API. This is an HTTP client for Ruby that can be used in a way that is similar to the Fetch API.

This is not intended to be a complete copy of the Fetch API. For example, responses are returned synchronously rather than asynchronously, as that is more familiar behavior for Ruby programmers. It is only "like" the Fetch API.

## Installation

Install the gem and add to the application's Gemfile by executing:

```
$ bundle add fetch-api
```

If bundler is not being used to manage dependencies, install the gem by executing:

```
$ gem install fetch-api
```

## Usage

### Basic

``` ruby
require 'fetch-api'

res = Fetch::API.fetch('https://example.com')

# res is a Rack::Response object
puts res.body
```

or

``` ruby
require 'fetch-api'

include Fetch::API

res = fetch('https://example.com')
```

Supported options are as follows:

- `method`: HTTP method (default: `'GET'`)
- `headers`: HTTP headers (default: `{}`)
- `body`: HTTP body (default: `nil`)
- `redirect`: Follow redirects (one of `follow`, `error`, `manual`, default: `follow`)

### Post JSON

``` ruby
res = fetch('http://example.com', **{
  method: 'POST',

  headers: {
    'Content-Type' => 'application/json'
  },

  body: {
    name: 'Alice'
  }.to_json
})
```

### Post Form

``` ruby
res = fetch('http://example.com', **{
  method: 'POST',

  headers: {
    'Content-Type' => 'multipart/form-data'
  },

  body: Rack::Multipart.build_multipart(
    file: Rack::Multipart::UploadedFile.new(io: StringIO.new('foo'), filename: 'foo.txt')
  )
})
```

Note: `Rack::Multipart.build_multipart` returns nil if the parameter does not include UploadedFile.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ursm/fetch-api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
