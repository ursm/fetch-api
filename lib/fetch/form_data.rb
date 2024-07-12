require_relative 'multi_map'

module Fetch
  class FormData < MultiMap
    def self.build(enumerable)
      data = FormData.new

      enumerable.each do |k, v|
        data.append k, v
      end

      data
    end

    private

    def to_key(key)
      key.to_s
    end

    def to_value(value)
      File === value ? value : value.to_s
    end
  end
end
