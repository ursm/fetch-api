require 'spec_helper'

RSpec.describe Fetch::URLSearchParams do
  describe '#initialize' do
    example 'with no arguments' do
      params = Fetch::URLSearchParams.new

      expect(params.entries).to eq([])
    end

    example 'with a string' do
      params = Fetch::URLSearchParams.new('foo=bar&foo=baz')

      expect(params.entries).to eq([
        ['foo', 'bar'],
        ['foo', 'baz']
      ])
    end

    example 'with an enumerable' do
      params = Fetch::URLSearchParams.new(
        foo: 'bar'
      )

      expect(params.entries).to eq([
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
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'

    expect(params.entries).to eq([
      ['foo', 'bar']
    ])

    params.append :foo, 'baz'

    expect(params.entries).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end

  example '#delete' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'
    params.append 'qux', 'quux'

    params.delete 'foo'

    expect(params.entries).to eq([
      ['qux', 'quux']
    ])
  end

  example '#get' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'

    expect(params.get('foo')).to eq('bar')
    expect(params.get('qux')).to be_nil
  end

  example '#get_all' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'

    expect(params.get_all('foo')).to eq(['bar', 'baz'])
    expect(params.get_all('qux')).to eq([])
  end

  example '#has' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'

    expect(params.has('foo')).to be_truthy
  end

  example '#keys' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'
    params.append 'qux', 'quux'

    expect(params.keys).to eq(['foo', 'foo', 'qux'])
  end

  example '#set' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'

    params.set 'foo', 'qux'

    expect(params.entries).to eq([
      ['foo', 'qux']
    ])
  end

  example '#sort' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'baz'
    params.append 'qux', 'quux'
    params.append 'foo', 'bar'

    params.sort

    expect(params.entries).to eq([
      ['foo', 'baz'],
      ['foo', 'bar'],
      ['qux', 'quux']
    ])
  end

  example '#to_s' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'
    params.append 'qux', 'quux'

    expect(params.to_s).to eq('foo=bar&foo=baz&qux=quux')
  end

  example '#values' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'
    params.append 'qux', 'quux'

    expect(params.values).to eq(['bar', 'baz', 'quux'])
  end

  example '#each' do
    params = Fetch::URLSearchParams.new

    params.append 'foo', 'bar'
    params.append 'foo', 'baz'

    expect(params.each).to be_a(Enumerator)

    expect(params.to_a).to eq([
      ['foo', 'bar'],
      ['foo', 'baz']
    ])
  end
end
