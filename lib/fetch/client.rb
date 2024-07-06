require_relative '../fetch'

require 'net/http'
require 'net/https'
require 'rack/response'
require 'singleton'
require 'uri'

module Fetch
  class Client
    include Singleton

    def fetch(resource, method: 'GET', headers: {}, body: nil, redirect: 'follow')
      uri = URI.parse(resource)
      req = Net::HTTP.const_get(method.capitalize).new(uri)

      headers.each do |k, v|
        req[k] = v
      end

      req.body = body

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'

      res = http.start { _1.request(req) }

      case res
      when Net::HTTPRedirection
        case redirect
        when 'follow'
          fetch(res['location'], method:, headers:, body:, redirect:)
        when 'error'
          raise RedirectError, "redirected to #{res['location']}"
        when 'manual'
          to_rack_response(res)
        else
          raise ArgumentError, "invalid redirect option: #{redirect}"
        end
      else
        to_rack_response(res)
      end
    end

    private

    def to_rack_response(res)
      Rack::Response.new(res.body, res.code, res.to_hash)
    end
  end
end
