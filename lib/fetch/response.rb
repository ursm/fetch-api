require 'json'
require 'rack/utils'

module Fetch
  Response = Data.define(:url, :status, :headers, :body, :redirected) {
    def ok
      status.between?(200, 299)
    end

    def status_text
      Rack::Utils::HTTP_STATUS_CODES[status]
    end

    def json(...)
      JSON.parse(body, ...)
    end
  }
end
