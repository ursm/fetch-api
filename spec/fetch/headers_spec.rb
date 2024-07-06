require 'spec_helper'

RSpec.describe Fetch::Headers do
  example 'append' do
    headers = Fetch::Headers.new

    headers.append :foo,  'bar'
    headers.append 'Foo', 'baz'

    expect(headers.entries).to eq([
      ['foo', 'bar, baz'],
    ])
  end

  example 'delete' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    headers.delete :baz

    expect(headers.entries).to eq([
      ['foo', 'bar']
    ])
  end

  example 'get' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    expect(headers.get(:foo)).to eq('bar')
    expect(headers.get(:baz)).to eq('qux, quux')
    expect(headers.get(:foobar)).to eq(nil)
  end

  example 'has' do
    headers = Fetch::Headers.new(foo: 'bar')

    expect(headers.has(:foo)).to eq(true)
    expect(headers.has(:bar)).to eq(false)
  end

  example 'keys' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    expect(headers.keys).to eq(%w[foo baz])
  end

  example 'set' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    headers.set :baz, 'foobar'

    expect(headers.entries).to eq([
      ['foo', 'bar'],
      ['baz', 'foobar']
    ])
  end

  example 'values' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    expect(headers.values).to eq(['bar', 'qux, quux'])
  end

  example 'each' do
    headers = Fetch::Headers.new([
      [:foo, 'bar'],
      [:baz, 'qux'],
      [:baz, 'quux']
    ])

    expect(headers.to_a).to eq([
      ['foo', 'bar'],
      ['baz', 'qux, quux']
    ])
  end
end
