require_relative '../fetch'
require_relative 'form_data'
require_relative 'url_search_params'

require 'marcel'
require 'net/http'
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

      case body
      when FormData
        req.set_form body.entries.map {|k, v|
          if v.is_a?(File)
            [k, v, {
              filename:     File.basename(v.path),
              content_type: Marcel::MimeType.for(v) || 'application/octet-stream'
            }]
          else
            [k, v]
          end
        }, 'multipart/form-data'
      when URLSearchParams
        req['Content-Type'] ||= 'application/x-www-form-urlencoded'

        req.body = body.to_s
      else
        req.body = body
      end

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'

      res = http.start { _1.request(req) }

      case res
      when Net::HTTPRedirection
        case redirect
        when 'follow'
          fetch(res['Location'], method:, headers:, body:, redirect:)
        when 'error'
          raise RedirectError, "redirected to #{res['Location']}"
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
