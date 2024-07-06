require 'json'
require 'rack/multipart'

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
      body: '{"name":"Alice"}',

      headers: {
        'Content-Type' => 'application/json'
      }
    )
  end

  example 'post multipart' do
    stub_request :post, 'http://example.com'

    res = fetch('http://example.com', **{
      method: 'POST',

      headers: {
        'Content-Type' => 'multipart/form-data'
      },

      body: Rack::Multipart.build_multipart(
        file: Rack::Multipart::UploadedFile.new(io: StringIO.new('foo'), filename: 'foo.txt')
      )
    })

    expect(res).to be_ok

    expect(WebMock).to have_requested(:post, 'http://example.com').with(
      headers: {
        'Content-Type' => 'multipart/form-data'
      }
    ) {|req|
      expect(req.body).to include(<<~BODY.gsub("\n", "\r\n"))
        content-disposition: form-data; name="file"; filename="foo.txt"
        content-type: text/plain

        foo
      BODY
    }
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
