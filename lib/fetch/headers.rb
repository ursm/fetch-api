module Fetch
  class Headers
    include Enumerable

    def initialize(init = [])
      @entries = []

      init.each do |k, v|
        append k, v
      end
    end

    attr_reader :entries

    def append(key, value)
      @entries << [key.to_s.downcase, value]
    end

    def delete(key)
      @entries.delete_if {|k,| k == key.to_s.downcase }
    end

    def get(key)
      @entries.select {|k,| k == key.to_s.downcase }.map(&:last).join(', ')
    end

    def has(key)
      @entries.any? {|k,| k == key.to_s.downcase }
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

    def each(&block)
      return enum_for(:each) unless block_given?

      @entries.each(&block)
    end
  end
end
