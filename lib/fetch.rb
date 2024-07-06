require_relative 'fetch/version'
require_relative 'fetch/api'

module Fetch
  class Error < StandardError; end
  class RedirectError < Error; end
end
