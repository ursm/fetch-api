require_relative '../fetch'

module Fetch
  class ConnectionPool
    SWEEP_INTERVAL = 1

    def initialize
      @connections = {}
      @mutex       = Mutex.new
      @pid         = Process.pid
    end

    # The connection goes back to the pool only if the block completes. Otherwise it may still have a response in
    # flight, which must not leak into the next request.
    def with_connection(uri, &block)
      conn      = checkout(uri)
      completed = false

      begin
        result    = block.call(conn)
        completed = true

        result
      ensure
        completed ? checkin(uri, conn) : close([conn])
      end
    end

    private

    def checkout(uri)
      expired, entry = synchronize { [sweep, @connections[uri.origin]&.pop] }

      close expired

      entry&.first || connect(uri)
    end

    def checkin(uri, conn)
      synchronize do
        (@connections[uri.origin] ||= []) << [conn, now]

        start_sweeper unless @sweeper&.alive?
      end
    end

    def connect(uri)
      # @type var host: String
      host = uri.host

      Net::HTTP.new(host, uri.port).tap {|http|
        http.use_ssl = uri.scheme == 'https'

        Fetch.config.on_connection_create.call http, uri

        http.start
      }
    end

    def close(conns)
      conns.each do |conn|
        conn.finish
      rescue StandardError
        # The connection is discarded anyway.
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Connections inherited from the parent process share their sockets with it, so a forked process starts over.
    def synchronize(&block)
      @mutex.synchronize do
        unless @pid == Process.pid
          @connections = {}
          @pid         = Process.pid
        end

        block.call
      end
    end

    # The sweeper retires once the pool is empty. It clears @sweeper under the lock so that a concurrent checkin never
    # mistakes a retiring sweeper for a running one.
    def start_sweeper
      @sweeper = Thread.new {
        loop do
          # @type var expired: Array[Net::HTTP]
          expired = []
          retired = false

          synchronize do
            expired  = sweep
            retired  = @connections.empty?
            @sweeper = nil if retired
          end

          close expired

          break if retired

          sleep SWEEP_INTERVAL
        end
      }
    end

    # Removes the expired connections from the pool and returns them. They are closed outside the lock because closing
    # may take a while.
    def sweep
      max_idle_time = Fetch.config.connection_max_idle_time
      current       = now

      expired = @connections.flat_map {|_, entries|
        expired, idle = entries.partition {|_, last_used| current - last_used > max_idle_time }

        entries.replace idle

        expired.map(&:first)
      }

      @connections.delete_if do |_, entries|
        entries.empty?
      end

      expired
    end
  end
end
