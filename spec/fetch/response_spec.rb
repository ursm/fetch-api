require 'spec_helper'

require 'active_support/core_ext/object/with'

RSpec.describe Fetch::Response do
  def create_response(url: 'http://example.com', status: 200, headers: [], body: nil, redirected: false)
    Fetch::Response.new(url:, status:, headers:, body:, redirected:)
  end

  example '#ok' do
    ok = create_response(status: 200)
    ng = create_response(status: 404)

    expect(ok.ok).to eq(true)
    expect(ng.ok).to eq(false)
  end

  example '#status_text' do
    res = create_response(status: 200)

    expect(res.status_text).to eq('OK')
  end

  example '#json' do
    res = create_response(body: '{"foo":"bar"}')

    expect(res.json).to eq('foo' => 'bar')
  end

  example '#json with config' do
    Fetch::config.with json_parse_options: {symbolize_names: true} do
      res = create_response(body: '{"foo":"bar"}')

      expect(res.json).to eq(foo: 'bar')
    end
  end
end
