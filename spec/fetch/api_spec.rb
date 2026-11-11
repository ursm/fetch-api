require 'json'

RSpec.describe Fetch::API do
  include Fetch::API

  example 'simple get' do
    res = fetch('http://localhost:4423')

    expect(res.url).to eq('http://localhost:4423')
    expect(res.status).to eq(200)
    expect(res.headers.to_h).to include('content-type' => 'application/json')
    expect(res.redirected).to eq(false)

    expect(res.json(symbolize_names: true)).to include(
      method: 'GET',
      body:   ''
    )
  end

  example 'post JSON' do
    res = fetch('http://localhost:4423', **{
      method: :post,

      headers: {
        'Content-Type' => 'application/json'
      },

      body: {
        name: 'Alice'
      }.to_json
    })

    expect(res.json(symbolize_names: true)).to match(
      method: 'POST',

      headers: include(
        'content-type': 'application/json'
      ),

      body: '{"name":"Alice"}'
    )
  end

  example 'post urlencoded' do
    res = fetch('http://localhost:4423', **{
      method: :post,
      body:   Fetch::URLSearchParams.new(name: 'Alice')
    })

    expect(res.json(symbolize_names: true)).to match(
      method: 'POST',

      headers: include(
        'content-type': 'application/x-www-form-urlencoded'
      ),

      body: 'name=Alice'
    )
  end

  example 'post multipart' do
    res = nil

    File.open 'spec/fixtures/files/foo.txt' do |f|
      res = fetch('http://localhost:4423', **{
        method: :post,

        headers: {
          'Content-Type' => 'multipart/form-data'
        },

        body: Fetch::FormData.build(
          name: 'Alice',
          file: f
        )
      })
    end

    expect(res.json(symbolize_names: true)).to match(
      method: 'POST',

      headers: include(
        'content-type': start_with('multipart/form-data; boundary=')
      ),

      body: include(<<~NAME.gsub("\n", "\r\n"), <<~FILE.gsub("\n", "\r\n"))
        Content-Disposition: form-data; name="name"

        Alice
      NAME
        Content-Disposition: form-data; name="file"; filename="foo.txt"
        Content-Type: text/plain

        bar
      FILE
    )
  end

  example 'redirect: follow' do
    res = fetch('http://localhost:4423/redirect', redirect: :follow)

    expect(res.status).to eq(200)
    expect(res.redirected).to eq(true)
    expect(res.url).to eq('http://localhost:4423/redirected')
  end

  example 'redirect: follow with a relative location' do
    res = fetch('http://localhost:4425/raw/relative')

    expect(res.status).to eq(200)
    expect(res.url).to eq('http://localhost:4425/redirected')
  end

  example 'redirect: follow with a location that needs to be percent-encoded' do
    res = fetch('http://localhost:4425/raw/unicode')

    expect(res.status).to eq(200)
    expect(res.url).to eq("http://localhost:4425/#{URI.encode_uri_component('リダイレクト')}%20#{URI.encode_uri_component('先')}")
  end

  example 'redirect: follow up to 20 redirects' do
    res = fetch('http://localhost:4423/redirect/chain/20')

    expect(res.status).to eq(200)
    expect(res.url).to eq('http://localhost:4423/redirect/chain/0')

    expect {
      fetch 'http://localhost:4423/redirect/chain/21'
    }.to raise_error(Fetch::RedirectError, /too many redirects/)
  end

  example 'redirect: follow to an unsupported or invalid URL' do
    expect {
      fetch 'http://localhost:4423/redirect/unsupported'
    }.to raise_error(Fetch::RedirectError, /unsupported URL/)

    expect {
      fetch 'http://localhost:4425/raw/invalid'
    }.to raise_error(Fetch::RedirectError, /invalid URL/)

    expect {
      fetch 'http://localhost:4425/raw/no-host'
    }.to raise_error(Fetch::RedirectError, /unsupported URL/)
  end

  example 'redirect: follow only on redirect statuses with a location' do
    [300, 304].each do |status|
      res = fetch("http://localhost:4423/redirect/#{status}")

      expect(res.status).to eq(status)
      expect(res.redirected).to eq(false)
    end

    res = fetch('http://localhost:4423/status/302')

    expect(res.status).to eq(302)
    expect(res.redirected).to eq(false)
  end

  example 'redirect: follow rewrites the method to GET and drops the body' do
    [
      [301, :post],
      [302, :post],
      [303, :post],
      [303, :put]
    ].each do |status, method|
      res = fetch("http://localhost:4423/redirect/#{status}", **{
        method:,
        body:   'foo',

        headers: {
          'Content-Type' => 'text/plain',
          'X-Foo'        => 'bar'
        }
      })

      json = res.json(symbolize_names: true)

      expect(json).to include(method: 'GET', body: '')
      expect(json[:headers]).to include('x-foo': 'bar')
      expect(json[:headers]).not_to include(:'content-type', :'content-length')
    end
  end

  example 'redirect: follow preserves the method and body' do
    [
      [301, :put],
      [302, :put],
      [307, :post],
      [308, :post]
    ].each do |status, method|
      res = fetch("http://localhost:4423/redirect/#{status}", **{
        method:,
        body:   'foo',

        headers: {
          'Content-Type' => 'text/plain'
        }
      })

      expect(res.json(symbolize_names: true)).to match(
        method: method.to_s.upcase,
        body:   'foo',

        headers: include(
          'content-type': 'text/plain'
        )
      )
    end
  end

  example 'redirect: follow preserves HEAD on 303' do
    res = fetch('http://localhost:4423/redirect/303', method: :head)

    expect(res.status).to eq(200)
    expect(res.redirected).to eq(true)
    expect(res.body).to be_nil
  end

  example 'redirect: follow resends files on 307' do
    File.open 'spec/fixtures/files/foo.txt' do |file|
      res = fetch('http://localhost:4423/redirect/307', **{
        method: :post,

        body: Fetch::FormData.build(
          file:
        )
      })

      expect(res.json(symbolize_names: true)[:body]).to include('bar')
    end
  end

  example 'redirect: follow keeps Authorization only on the same origin' do
    headers = {
      'Authorization' => 'Bearer secret'
    }

    same_origin  = fetch('http://localhost:4423/redirect', headers:)
    cross_origin = fetch('http://localhost:4423/redirect/cross-origin', headers:)

    expect(cross_origin.url).to eq('http://localhost:4424/redirected')

    expect(same_origin.json(symbolize_names: true)[:headers]).to include(authorization: 'Bearer secret')
    expect(cross_origin.json(symbolize_names: true)[:headers]).not_to include(:authorization)
  end

  example 'redirect: error' do
    expect {
      fetch 'http://localhost:4423/redirect', redirect: :error
    }.to raise_error(Fetch::RedirectError)
  end

  example 'redirect: manual' do
    res = fetch('http://localhost:4423/redirect', redirect: :manual)

    expect(res.status).to eq(302)
    expect(res.redirected).to eq(false)
    expect(res.url).to eq('http://localhost:4423/redirect')
  end

  example 'redirect: error without a location' do
    expect {
      fetch 'http://localhost:4423/status/302', redirect: :error
    }.to raise_error(Fetch::RedirectError, 'redirected without a location')
  end

  example 'redirect: invalid' do
    expect {
      fetch 'http://localhost:4423', redirect: :foo
    }.to raise_error(ArgumentError, /invalid redirect option/)
  end

  example 'non-HTTP URL' do
    expect {
      fetch 'ftp://example.com/'
    }.to raise_error(ArgumentError, /not an HTTP URL/)
  end

  example 'repeated headers' do
    res = fetch('http://localhost:4423', headers: [
      %w(X-Foo bar),
      %w(X-Foo baz)
    ])

    expect(res.json(symbolize_names: true)[:headers]).to include('x-foo': 'bar, baz')
  end

  example 'thread safety' do
    bodies = 10.times.map {
      Thread.new {
        res = fetch('http://localhost:4423', **{
          method: :post,
          body:   'foo'
        })

        res.json(symbolize_names: true).fetch(:body)
      }
    }.map(&:value)

    expect(bodies).to eq(['foo'] * 10)
  end
end
