require 'spec_helper'

RSpec.describe Fetch::URLSearchParams do
  describe '#initialize' do
    example 'with no arguments' do
      data = Fetch::URLSearchParams.new

      expect(data.entries).to eq([])
    end

    example 'with a string' do
      data = Fetch::URLSearchParams.new('foo=bar&foo=baz')

      expect(data.entries).to eq([
        ['foo', 'bar'],
        ['foo', 'baz']
      ])
    end

    example 'with an enumerable' do
      data = Fetch::URLSearchParams.new(
        foo: 'bar'
      )

      expect(data.entries).to eq([
        ['foo', 'bar']
      ])
    end

    example 'with an invalid argument' do
      expect {
        Fetch::URLSearchParams.new(123)
      }.to raise_error(ArgumentError)
    end
  end

  example '#append' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'

    expect(data.entries).to eq([
      ['foo', 'bar']
    ])

    data.append :foo, 'baz'

    expect(data.entries).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end

  example '#delete' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    data.delete 'foo'

    expect(data.entries).to eq([
      ['qux', 'quux']
    ])
  end

  example '#get' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.get('foo')).to eq('bar')
    expect(data.get('qux')).to be_nil
  end

  example '#get_all' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.get_all('foo')).to eq(['bar', 'baz'])
    expect(data.get_all('qux')).to eq([])
  end

  example '#has' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'

    expect(data.has('foo')).to be_truthy
  end

  example '#keys' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    expect(data.keys).to eq(['foo', 'foo', 'qux'])
  end

  example '#set' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    data.set 'foo', 'qux'

    expect(data.entries).to eq([
      ['foo', 'qux']
    ])
  end

  example '#sort' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'baz'
    data.append 'qux', 'quux'
    data.append 'foo', 'bar'

    data.sort

    expect(data.entries).to eq([
      ['foo', 'baz'],
      ['foo', 'bar'],
      ['qux', 'quux']
    ])
  end

  example '#to_s' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    expect(data.to_s).to eq('foo=bar&foo=baz&qux=quux')
  end

  example '#values' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'
    data.append 'qux', 'quux'

    expect(data.values).to eq(['bar', 'baz', 'quux'])
  end

  example '#each' do
    data = Fetch::URLSearchParams.new

    data.append 'foo', 'bar'
    data.append 'foo', 'baz'

    expect(data.each.to_a).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end
end
