module Fetch
  class MultiMap
    include Enumerable

    def initialize
      @entries = []
    end

    attr_reader :entries

    def append(key, value)
      @entries.push [to_key(key), to_value(value)]
    end

    def delete(key)
      @entries.reject! {|k,| k == to_key(key) }
    end

    def get(key)
      @entries.assoc(to_key(key))&.last
    end

    def get_all(key)
      @entries.select {|k,| k == to_key(key) }.map(&:last)
    end

    def has(key)
      @entries.any? {|k,| k == to_key(key) }
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

    def each(&)
      @entries.each(&)
    end

    private

    def to_key(key)
      raise NotImplementedError
    end

    def to_value(value)
      raise NotImplementedError
    end
  end
end
