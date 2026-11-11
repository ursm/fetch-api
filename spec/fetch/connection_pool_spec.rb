require 'spec_helper'

require 'active_support/core_ext/object/with'

RSpec.describe Fetch::ConnectionPool do
  let(:uri) { URI.parse('http://localhost:4423') }

  example 'reusing connections' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 3 do
      conn1 = pool.with_connection(uri, &:itself)
      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).to eq(conn2)
    end
  end

  example 'not reusing idle connections' do
    stub_const 'Fetch::ConnectionPool::SWEEP_INTERVAL', 10

    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 0.1 do
      conn1 = pool.with_connection(uri, &:itself)
      sleep 0.2
      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).not_to eq(conn2)
      expect(conn1).not_to be_started
    end
  end

  example 'not reusing connections whose request was interrupted' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 3 do
      conn1 = nil

      expect {
        pool.with_connection uri do |conn|
          conn1 = conn

          raise Timeout::Error
        end
      }.to raise_error(Timeout::Error)

      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).not_to eq(conn2)
      expect(conn1).not_to be_started
    end
  end

  example 'pooling multiple connections per origin' do
    pool = Fetch::ConnectionPool.new

    checkout_two = -> {
      pool.with_connection(uri) {|conn1|
        pool.with_connection(uri) {|conn2|
          [conn1, conn2]
        }
      }
    }

    Fetch.config.with connection_max_idle_time: 3 do
      conns = checkout_two.call

      expect(conns.uniq.size).to eq(2)
      expect(checkout_two.call).to match_array(conns)
    end
  end

  example 'closing idle connections in the background' do
    stub_const 'Fetch::ConnectionPool::SWEEP_INTERVAL', 0.05

    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 0.1 do
      conn = pool.with_connection(uri, &:itself)
      sleep 0.3

      expect(conn).not_to be_started
    end
  end

  example 'closing the remaining connections even if one fails to close' do
    stub_const 'Fetch::ConnectionPool::SWEEP_INTERVAL', 0.05

    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 0.1 do
      conn = pool.with_connection(uri) {|outer|
        pool.with_connection uri do |inner|
          allow(inner).to receive(:finish).and_raise(Errno::EPIPE)
        end

        outer
      }

      sleep 0.3

      expect(conn).not_to be_started
    end
  end

  example 'restarting the sweeper if it died' do
    stub_const 'Fetch::ConnectionPool::SWEEP_INTERVAL', 0.05

    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 0.1 do
      pool.with_connection(uri, &:itself)
      pool.instance_variable_get(:@sweeper).kill.join

      conn = pool.with_connection(uri, &:itself)
      sleep 0.3

      expect(conn).not_to be_started
    end
  end

  example 'keeping connections forever' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: Float::INFINITY do
      conn1 = pool.with_connection(uri, &:itself)
      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).to eq(conn2)
    end
  end

  example 'discarding connections inherited by a forked process' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with connection_max_idle_time: 3 do
      conn           = pool.with_connection(uri, &:itself)
      reader, writer = IO.pipe

      pid = fork {
        reused = pool.with_connection(uri) { _1.equal?(conn) }

        writer.write({reused:, started: conn.started?}.to_json)
        exit!
      }

      writer.close
      Process.wait pid

      expect(JSON.parse(reader.read, symbolize_names: true)).to eq(reused: false, started: true)
    end
  end
end
