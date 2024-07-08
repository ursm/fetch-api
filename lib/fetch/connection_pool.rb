require_relative '../fetch'

require 'thread'

module Fetch
  class ConnectionPool
    Entry = Struct.new(:connection, :in_use, :last_used, keyword_init: true)

    def initialize
      @connections = {}
      @mutex       = Mutex.new

      @sweeper = Thread.new {
        loop do
          sleep 1

          sweep

          Thread.stop if @connections.empty?
        end
      }
    end

    def with_connection(uri, &block)
      conn = acquire(uri)

      begin
        block.call(conn)
      ensure
        release uri
      end
    end

    private

    def acquire(uri)
      @mutex.synchronize {
        entry = @connections[key(uri)]

        if entry
          entry.in_use = true

          entry.connection
        else
          Net::HTTP.new(uri.host, uri.port).tap {|http| # steep:ignore ArgumentTypeMismatch
            http.use_ssl            = uri.scheme == 'https'
            http.keep_alive_timeout = Fetch.config.keep_alive_timeout

            @connections[key(uri)] = Entry.new(connection: http, in_use: true)

            http.start
          }
        end
      }.tap {
        @sweeper.wakeup
      }
    end

    def release(uri)
      @mutex.synchronize do
        if entry = @connections[key(uri)]
          entry.in_use    = false
          entry.last_used = Time.now
        end
      end
    end

    def sweep
      @mutex.synchronize do
        @connections.each do |key, entry|
          next if entry.in_use

          if entry.last_used + Fetch.config.connection_max_idle_time < Time.now
            entry.connection.finish

            @connections.delete key
          end
        end
      end
    end

    def key(uri)
      "#{Thread.current.object_id}/#{uri.origin}".freeze
    end
  end
end
