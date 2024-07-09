require 'spec_helper'

require 'active_support/core_ext/object/with'

RSpec.describe Fetch::ConnectionPool do
  let(:uri) { URI.parse('http://localhost:4423') }

  example 'reusing connections' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with max_idle_time: 10 do
      conn1 = pool.with_connection(uri, &:itself)
      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).to eq(conn2)
    end
  end

  example 'closing idle connections' do
    pool = Fetch::ConnectionPool.new

    Fetch.config.with max_idle_time: 0 do
      conn1 = pool.with_connection(uri, &:itself)
      Thread.pass
      conn2 = pool.with_connection(uri, &:itself)

      expect(conn1).not_to eq(conn2)
    end
  end
end
