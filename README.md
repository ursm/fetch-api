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

# res is a Fetch::Response object
puts res.body
```

or

``` ruby
require 'fetch-api'

include Fetch::API

res = fetch('https://example.com')
```

Options for `fetch` method:

- `method`: HTTP method (default: `'GET'`)
- `headers`: Request headers (default: `{}`)
- `body`: Request body (default: `nil`)
- `redirect`: Follow redirects (one of `'follow'`, `'error'`, `'manual'`, default: `'follow'`)

Methods of `Fetch::Response` object:

- `body`: Response body (String)
- `headers`: Response headers
- `ok`: Whether the response was successful or not (status code is in the range 200-299)
- `redirected`: Whether the response is the result of a redirect
- `status`: Status code (e.g. `200`, `404`)
- `status_text`: Status text (e.g. `'OK'`, `'Not Found'`)
- `url`: Response URL
- `json(**args)`: An object that parses the response body as JSON. The arguments are passed to `JSON.parse`

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

### Post application/x-www-form-urlencoded

``` ruby
res = fetch('http://example.com', **{
  method: 'POST',

  body: Fetch::URLSearchParams.new(
    name: 'Alice'
  )
})
```

### Post multipart/form-data

``` ruby
res = fetch('http://example.com', **{
  method: 'POST',

  body: Fetch::FormData.build(
    name: 'Alice',
    file: File.open('path/to/file.txt')
  )
})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ursm/fetch-api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
