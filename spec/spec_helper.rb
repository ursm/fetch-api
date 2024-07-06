require 'fetch-api'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each do |f|
  require f
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
