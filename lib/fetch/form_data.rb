require 'forwardable'

module Fetch
  class FormData
    include Enumerable

    extend Forwardable

    def_delegators :entries, :each

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
      @entries.push [key.to_s, value.is_a?(File) ? value : value.to_s]
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

    def values
      @entries.map(&:last)
    end
  end
end
