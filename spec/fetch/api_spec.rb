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
