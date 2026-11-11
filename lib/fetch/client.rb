require_relative 'connection_pool'
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

    MAX_REDIRECTS     = 20
    REDIRECT_STATUSES = [301, 302, 303, 307, 308]
    REDIRECT_MODES    = %w(follow error manual)

    BODY_HEADERS = %w(
      content-encoding
      content-language
      content-length
      content-location
      content-type
    )

    def initialize
      @pool = ConnectionPool.new
    end

    def fetch(resource, method:, headers:, body:, redirect:)
      raise ArgumentError, "invalid redirect option: #{redirect.inspect}" unless REDIRECT_MODES.include?(redirect.to_s)

      uri     = URI.parse(resource)
      method  = method.to_s.upcase
      headers = Headers.new(headers)

      raise ArgumentError, "not an HTTP URL: #{uri}" unless uri.is_a?(URI::HTTP)

      MAX_REDIRECTS.succ.times do |redirect_count|
        res      = request(uri, method, headers, body)
        response = to_response(uri, res, redirect_count > 0)
        location = res['Location']

        return response if !REDIRECT_STATUSES.include?(response.status) || redirect.to_s == 'manual'

        raise RedirectError, location ? "redirected to #{location}" : 'redirected without a location' if redirect.to_s == 'error'

        return response unless location

        redirected_uri = resolve(uri, location)

        if rewrite_to_get?(response.status, method)
          method = 'GET'
          body   = nil

          BODY_HEADERS.each do |name|
            headers.delete name
          end
        end

        headers.delete 'authorization' unless redirected_uri.origin == uri.origin

        rewind body

        uri = redirected_uri
      end

      raise RedirectError, "too many redirects (more than #{MAX_REDIRECTS})"
    end

    private

    def request(uri, method, headers, body)
      req = Net::HTTP.const_get(method.capitalize).new(uri)

      headers.each do |k, v|
        req[k] = v
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

      @pool.with_connection(uri) { _1.request(req) }
    end

    # Like browsers, percent-encodes the characters that are not allowed in a URL instead of rejecting them.
    def resolve(uri, location)
      redirected_uri = URI.join(uri, location.b.gsub(/[^\x21-\x7e]/n) { format('%%%02X', _1.ord) })

      raise RedirectError, "redirected to unsupported URL: #{location}" unless redirected_uri.is_a?(URI::HTTP) && !redirected_uri.host.to_s.empty?

      redirected_uri
    rescue URI::InvalidURIError
      raise RedirectError, "redirected to invalid URL: #{location}"
    end

    def rewrite_to_get?(status, method)
      case status
      when 301, 302
        method == 'POST'
      when 303
        !%w(GET HEAD).include?(method)
      else
        false
      end
    end

    def rewind(body)
      return unless body.is_a?(FormData)

      body.each do |_, v|
        v.rewind if v.is_a?(File)
      end
    end

    def to_response(uri, res, redirected)
      Response.new(
        url:        uri.to_s,
        status:     res.code.to_i,
        headers:    Headers.new(res.each),
        body:       res.body,
        redirected:
      )
    end
  end
end
