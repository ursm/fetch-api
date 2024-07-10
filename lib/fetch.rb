require_relative 'fetch/config'

module Fetch
  singleton_class.attr_accessor :config

  self.config = Config.new

  def self.configure(&block)
    block.call(config)
  end

  configure do |config|
    config.max_idle_time      = 30
    config.keep_alive_timeout = 15
  end
end
