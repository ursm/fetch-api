require 'json'
require 'rack/utils'

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
      Rack::Utils::HTTP_STATUS_CODES[status]
    end

    def json(...)
      return nil unless body

      JSON.parse(body, ...)
    end
  end
end
