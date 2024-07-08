require_relative 'fetch/config'

module Fetch
  singleton_class.attr_accessor :config

  self.config = Config.new

  def self.configure(&block)
    block.call(config)
  end

  configure do |config|
    config.connection_max_idle_time = 10
    config.keep_alive_timeout       = 2
  end
end
