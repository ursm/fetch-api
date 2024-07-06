require_relative 'errors'
require_relative 'form_data'
require_relative 'headers'
require_relative 'response'
require_relative 'url_search_params'

require 'marcel'
require 'net/http'
require 'singleton'
require 'uri'

module Fetch
  class Client
    include Singleton

    def fetch(resource, method: 'GET', headers: [], body: nil, redirect: 'follow', _redirected: false)
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
          fetch(res['Location'], method:, headers:, body:, redirect:, _redirected: true)
        when 'error'
          raise RedirectError, "redirected to #{res['Location']}"
        when 'manual'
          to_response(resource, res, _redirected)
        else
          raise ArgumentError, "invalid redirect option: #{redirect}"
        end
      else
        to_response(resource, res, _redirected)
      end
    end

    private

    def to_response(url, res, redirected)
      Response.new(
        url:        ,
        status:     res.code.to_i,
        headers:    Headers.new(res),
        body:       res.body,
        redirected:
      )
    end
  end
end
