module Fetch
  module SymbolToStr
    refine Symbol do
      def to_str
        to_s
      end
    end
  end
end
