require_relative 'fetch/version'

module Fetch
  class Error < StandardError; end
  class RedirectError < Error; end
end
