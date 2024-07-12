require_relative 'multi_map'

require 'uri'

module Fetch
  class URLSearchParams < MultiMap
    def initialize(options = [])
      super()

      case options
      when String
        initialize(URI.decode_www_form(options.delete_prefix('?')))
      when Enumerable
        options.each do |k, v|
          append k, v
        end
      else
        raise ArgumentError
      end
    end

    def sort
      entries.sort_by!(&:first)
    end

    def to_s
      URI.encode_www_form(entries)
    end

    private

    def to_key(key)
      key.to_s
    end

    def to_value(value)
      value.to_s
    end
  end
end
