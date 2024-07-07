require_relative 'errors'
require_relative 'form_data'
require_relative 'headers'
require_relative 'response'
require_relative 'url_search_params'

require 'mini_mime'
require 'net/http'
require 'net/https'
require 'singleton'
require 'uri'

module Fetch
  class Client
    include Singleton

    def fetch(resource, method: :get, headers: [], body: nil, redirect: :follow, _redirected: false)
      uri = URI.parse(resource)
      req = Net::HTTP.const_get(method.capitalize).new(uri)

      headers.each do |k, v|
        req[k.to_s] = v.to_s
      end

      case body
      when FormData
        req.set_form body.map {|k, v|
          if v.is_a?(File)
            [k, v, {
              filename:     File.basename(v.path),
              content_type: MiniMime.lookup_by_filename(v.path)&.content_type || 'application/octet-stream'
            }]
          else
            [k, v]
          end
        }, 'multipart/form-data'
      when URLSearchParams
        req.set_form_data body.entries
      else
        req.body = body
      end

      http = Net::HTTP.new(uri.hostname, uri.port) # steep:ignore ArgumentTypeMismatch
      http.use_ssl = uri.scheme == 'https'

      res = http.start { _1.request(req) }

      case res
      when Net::HTTPRedirection
        case redirect.to_s
        when 'follow'
          fetch(res['Location'], method:, headers:, body:, redirect:, _redirected: true) # steep:ignore ArgumentTypeMismatch
        when 'error'
          raise RedirectError, "redirected to #{res['Location']}"
        when 'manual'
          to_response(resource, res, _redirected)
        else
          raise ArgumentError, "invalid redirect option: #{redirect.inspect}"
        end
      else
        to_response(resource, res, _redirected)
      end
    end

    private

    def to_response(url, res, redirected)
      Response.new(
        url:        url.to_str,
        status:     res.code.to_i,
        headers:    Headers.new(res.each),
        body:       res.body,
        redirected:
      )
    end
  end
end
