require 'json'

RSpec.describe Fetch::API do
  include Fetch::API

  example 'simple get' do
    stub_request :get, 'http://example.com'

    res = fetch('http://example.com')

    expect(res).to be_ok
  end

  example 'https' do
    stub_request :get, 'https://example.com'

    res = fetch('https://example.com')

    expect(res).to be_ok
  end

  example 'post JSON' do
    stub_request :post, 'http://example.com'

    res = fetch('http://example.com', **{
      method: 'POST',

      headers: {
        'Content-Type' => 'application/json'
      },

      body: {
        name: 'Alice'
      }.to_json
    })

    expect(res).to be_ok

    expect(WebMock).to have_requested(:post, 'http://example.com').with(
      headers: {
        'Content-Type' => 'application/json'
      },

      body: '{"name":"Alice"}'
    )
  end

  example 'post form' do
    stub_request :post, 'http://example.com'

    res = fetch('http://example.com', **{
      method: 'POST',
      body:   Fetch::URLSearchParams.new(name: 'Alice')
    })

    expect(res).to be_ok

    expect(WebMock).to have_requested(:post, 'http://example.com').with(
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      },

      body: 'name=Alice'
    )
  end

  example 'post multipart' do
    stub_request :post, 'http://example.com'

    res = nil

    File.open 'spec/fixtures/files/foo.txt' do |f|
      res = fetch('http://example.com', **{
        method: 'POST',

        headers: {
          'Content-Type' => 'multipart/form-data'
        },

        body: Fetch::FormData.build(
          name: 'Alice',
          file: f
        )
      })
    end

    expect(res).to be_ok

    expect(WebMock).to have_requested(:post, 'http://example.com').with(
      headers: {
        'Content-Type' => 'multipart/form-data'
      }
    )

    # The request body should be sent correctly, but with webmock, the body becomes nil.
  end

  example 'redirect: follow' do
    stub_request(:get, 'http://example.com').to_return(status: 302, headers: {
      'Location' => 'http://example.com/redirected'
    })

    stub_request :get, 'http://example.com/redirected'

    res = fetch('http://example.com', redirect: 'follow')

    expect(res).to be_ok

    expect(WebMock).to have_requested(:get, 'http://example.com/redirected')
  end

  example 'redirect: error' do
    stub_request(:get, 'http://example.com').to_return(status: 302, headers: {
      'Location' => 'http://example.com/redirected'
    })

    expect {
      fetch('http://example.com', redirect: 'error')
    }.to raise_error(Fetch::RedirectError)
  end

  example 'redirect: manual' do
    stub_request(:get, 'http://example.com').to_return(status: 302, headers: {
      'Location' => 'http://example.com/redirected'
    })

    res = fetch('http://example.com', redirect: 'manual')

    expect(res).to be_redirect
  end
end
