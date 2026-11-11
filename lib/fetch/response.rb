require 'json'
require 'net/http/status'

module Fetch
  class Response
    def initialize(url:, status:, headers:, body:, redirected:)
      @url        = url
      @status     = status
      @headers    = headers
      @body       = body
      @redirected = redirected
    end

    attr_reader :url, :status, :headers, :body, :redirected

    def ok
      status.between?(200, 299)
    end

    def status_text
      Net::HTTP::STATUS_CODES[status]
    end

    def json(**json_parse_options)
      return nil unless body

      JSON.parse(body, **Fetch.config.json_parse_options, **json_parse_options)
    end
  end
end
