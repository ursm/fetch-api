require_relative 'symbol_to_str'

module Fetch
  class FormData
    include Enumerable

    using SymbolToStr

    def self.build(enumerable)
      data = FormData.new

      enumerable.each do |k, v|
        data.append k, v
      end

      data
    end

    def initialize
      @entries = []
    end

    attr_reader :entries

    def append(key, value)
      @entries.push [key.to_str, value]
    end

    def delete(key)
      @entries.reject! {|k,| k == key.to_str }
    end

    def get(key)
      @entries.assoc(key.to_str)&.last
    end

    def get_all(key)
      @entries.select {|k,| k == key.to_str }.map(&:last)
    end

    def has(key)
      @entries.any? {|k,| k == key.to_str }
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
  end
end
