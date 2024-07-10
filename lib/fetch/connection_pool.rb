require_relative '../fetch'

require 'concurrent/hash'

module Fetch
  class ConnectionPool
    def initialize
      @connections = Concurrent::Hash.new

      @sweeper = Thread.new {
        loop do
          sweep

          if @connections.empty?
            Thread.stop
          else
            sleep 1
          end
        end
      }
    end

    def with_connection(uri, &block)
      conn = checkout(uri)

      begin
        block.call(conn)
      ensure
        checkin uri, conn
      end
    end

    private

    def checkout(uri)
      if entry = @connections.delete(uri.origin)
        entry.first
      else
        # @type var host: String
        host = uri.host

        Net::HTTP.new(host, uri.port).tap {|http|
          http.use_ssl            = uri.scheme == 'https'
          http.keep_alive_timeout = Fetch.config.keep_alive_timeout
          http.start
        }
      end
    end

    def checkin(uri, conn)
      @connections[uri.origin] = [conn, Time.now]

      @sweeper.wakeup
    end

    def sweep
      @connections.each do |origin, (conn, last_used)|
        if last_used + Fetch.config.max_idle_time < Time.now
          begin
            conn.finish
          rescue IOError
            # do nothing
          end

          @connections.delete origin
        end
      end
    end
  end
end
