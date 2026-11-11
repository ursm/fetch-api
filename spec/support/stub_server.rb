require 'json'
require 'net/http'
require 'rack/request'
require 'rackup'
require 'socket'
require 'webrick'

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
  when '/redirect/cross-origin'
    [302, {'Location' => "#{req.scheme}://#{req.host}:4424/redirected"}, []]
  when '/redirect/unsupported'
    [302, {'Location' => 'ftp://example.com/'}, []]
  when %r{\A/redirect/chain/(\d+)\z}
    count = $1.to_i

    count.zero? ? [200, {}, []] : [302, {'Location' => "/redirect/chain/#{count - 1}"}, []]
  when %r{\A/redirect/(\d{3})\z}
    [$1.to_i, {'Location' => '/redirected'}, []]
  when %r{\A/status/(\d{3})\z}
    [$1.to_i, {}, []]
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

# WEBrick rewrites the Location header into an absolute URL, so the raw ones are served from a bare socket.
raw_locations = {
  '/raw/relative' => '../redirected',
  '/raw/invalid'  => 'http://example.com:foo/',
  '/raw/no-host'  => 'http:///foo',
  '/raw/unicode'  => '/リダイレクト 先'
}

serve_raw = -> (socket) {
  begin
    path     = socket.gets.to_s.split[1]
    location = raw_locations[path]

    nil until socket.gets.to_s.chomp.empty?

    socket.write location ? "HTTP/1.1 302 Found\r\nLocation: #{location}\r\n" : "HTTP/1.1 200 OK\r\n"
    socket.write "Content-Length: 0\r\nConnection: close\r\n\r\n"
  rescue SystemCallError, IOError
    # The client has gone away.
  ensure
    socket.close
  end
}

RSpec.configure do |config|
  ports   = [4423, 4424]
  servers = []

  config.before :suite do
    servers = ports.map {|port|
      Thread.new {
        Rackup::Server.start(
          app:       ,
          Port:      port,
          Logger:    WEBrick::BasicLog.new('/dev/null'),
          AccessLog: []
        )
      }
    }

    raw_server = TCPServer.new('localhost', 4425)

    servers << Thread.new {
      loop do
        serve_raw.call raw_server.accept
      end
    }

    Timeout.timeout 3 do
      ports.each do |port|
        Net::HTTP.get URI("http://localhost:#{port}")
      rescue Errno::ECONNREFUSED
        sleep 0.1
        retry
      end
    end
  end

  config.after :suite do
    servers.each(&:kill)
  end
end
