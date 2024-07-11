module Fetch
  class MultiMap
    include Enumerable

    def initialize
      @entries = []
    end

    attr_reader :entries

    def append(key, value)
      @entries.push [transform_key(key), transform_value(value)]
    end

    def delete(key)
      @entries.reject! {|k,| k == transform_key(key) }
    end

    def get(key)
      @entries.assoc(transform_key(key))&.last
    end

    def get_all(key)
      @entries.select {|k,| k == transform_key(key) }.map(&:last)
    end

    def has(key)
      @entries.any? {|k,| k == transform_key(key) }
    end

    def keys
      @entries.map(&:first)
    end

    def set(key, value)
      delete key
      append key, value
    end

    def values
      @entries.map(&:last)
    end

    def each(...)
      @entries.each(...)
    end

    private

    def transform_key(key)
      raise NotImplementedError
    end

    def transform_value(value)
      raise NotImplementedError
    end
  end
end
