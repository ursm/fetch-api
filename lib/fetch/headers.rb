module Fetch
  class Headers
    include Enumerable

    def initialize(init = [])
      @data = {}

      init.each do |k, v|
        append k, v
      end
    end

    def append(key, value)
      (@data[key.to_s.downcase] ||= []) << value.to_s
    end

    def delete(key)
      @data.delete key.to_s.downcase
    end

    def entries
      @data.map {|k, vs| [k, vs.join(', ')] }
    end

    def get(key)
      @data[key.to_s.downcase]&.join(', ')
    end

    def has(key)
      @data.key?(key.to_s.downcase)
    end

    def keys
      @data.keys
    end

    def set(key, value)
      @data[key.to_s.downcase] = [value]
    end

    def values
      @data.values.map { _1.join(', ') }
    end

    def each(&block)
      entries.each(&block)
    end
  end
end
