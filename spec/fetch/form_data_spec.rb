require 'spec_helper'

RSpec.describe Fetch::FormData do
  example '.build' do
    data = Fetch::FormData.build(
      foo: 'bar'
    )

    expect(data.entries).to eq([
      ['foo', 'bar']
    ])
  end

  example '#append' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'

    expect(data.entries).to eq([
      ['foo', 'bar']
    ])

    data.append 'foo', 'baz'

    expect(data.entries).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end

  example '#delete' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    data.delete 'foo'

    expect(data.entries).to eq([
      ['qux', 'quux']
    ])
  end

  example '#get' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.get('foo')).to eq('bar')
    expect(data.get('qux')).to be_nil
  end

  example '#get_all' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.get_all('foo')).to eq(['bar', 'baz'])
    expect(data.get_all('qux')).to eq([])
  end

  example '#has' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'

    expect(data.has('foo')).to be_truthy
    expect(data.has('qux')).to be_falsey
  end

  example '#keys' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    expect(data.keys).to eq(['foo', 'foo', 'qux'])
  end

  example '#set' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    data.set 'foo', 'qux'

    expect(data.entries).to eq([
      ['foo', 'qux']
    ])
  end

  example '#values' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    expect(data.values).to eq(['bar', 'baz', 'quux'])
  end

  example '#each' do
    data = Fetch::FormData.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.to_a).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end
end
