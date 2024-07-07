require_relative 'symbol_to_str'

module Fetch
  class Headers
    include Enumerable

    using SymbolToStr

    def initialize(init = [])
      @data = {}

      init.each do |k, v|
        append k, v
      end
    end

    def append(key, value)
      (@data[key.to_str.downcase] ||= []) << value
    end

    def delete(key)
      @data.delete key.to_str.downcase
    end

    def entries
      @data.map {|k, vs| [k, vs.join(', ')] }
    end

    def get(key)
      @data[key.to_str.downcase]&.join(', ')
    end

    def has(key)
      @data.key?(key.to_str.downcase)
    end

    def keys
      @data.keys
    end

    def set(key, value)
      @data[key.to_str.downcase] = [value]
    end

    def values
      @data.values.map { _1.join(', ') }
    end

    def each(&block)
      entries.each(&block)
    end
  end
end
