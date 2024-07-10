require_relative 'client'

module Fetch
  module API
    module_function

    def fetch(resource, method: :get, headers: [], body: nil, redirect: :follow)
      Client.instance.fetch(resource, method:, headers:, body:, redirect:)
    end
  end
end
