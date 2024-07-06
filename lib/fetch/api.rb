require_relative 'client'

module Fetch
  module API
    module_function

    def fetch(...)
      Client.instance.fetch(...)
    end
  end
end
