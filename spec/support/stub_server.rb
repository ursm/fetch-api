require 'json'
require 'net/http'
require 'rack/request'
require 'rackup'

app = -> (env) {
  req = Rack::Request.new(env)

  headers = req.each_header.to_h.select {|k,|
    k.start_with?('HTTP_') || %w(CONTENT_TYPE CONTENT_LENGTH).include?(k)
  }.transform_keys {|k|
    k.delete_prefix('HTTP_').downcase.tr('_', '-')
  }

  case req.path
  when '/redirect'
    [302, {'Location' => "#{req.scheme}://#{req.host_with_port}/redirected"}, []]
  else
    [
      200,
      {
        'Content-Type' => 'application/json'
      },
      [
        {
          method:  req.request_method,
          headers: ,
          body:    req.body.read,
        }.to_json
      ]
    ]
  end
}

RSpec.configure do |config|
  server = nil

  config.before :suite do
    server = Thread.new {
      Rackup::Server.start(
        app:       ,
        Port:      4423,
        Logger:    WEBrick::BasicLog.new('/dev/null'),
        AccessLog: []
      )
    }

    uri = URI('http://localhost:4423')

    Timeout.timeout 3 do
      loop do
        Net::HTTP.get uri
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end
  end

  config.after :suite do
    server.kill
  end
end
