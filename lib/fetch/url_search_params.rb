require 'forwardable'
require 'uri'

module Fetch
  class URLSearchParams
    include Enumerable

    extend Forwardable

    def_delegators :entries, :each

    def initialize(options = [])
      @entries = []

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

    attr_reader :entries

    def append(key, value)
      @entries.push [key.to_s, value.to_s]
    end

    def delete(key)
      @entries.reject! {|k,| k == key.to_s }
    end

    def get(key)
      @entries.assoc(key.to_s)&.last
    end

    def get_all(key)
      @entries.select {|k,| k == key.to_s }.map(&:last)
    end

    def has(key)
      @entries.any? {|k,| k == key.to_s }
    end

    def keys
      @entries.map(&:first)
    end

    def set(key, value)
      delete key
      append key, value
    end

    def sort
      @entries.sort_by!(&:first)
    end

    def to_s
      URI.encode_www_form(@entries)
    end

    def values
      @entries.map(&:last)
    end
  end
end
