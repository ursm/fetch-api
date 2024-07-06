require_relative 'lib/fetch/version'

Gem::Specification.new do |spec|
  spec.name    = 'fetch-api'
  spec.version = Fetch::VERSION
  spec.authors = ['Keita Urashima']
  spec.email   = ['ursm@ursm.jp']

  spec.summary               = 'Something like the Fetch API for Ruby'
  spec.homepage              = 'https://github.com/ursm/fetch-api'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ursm/fetch-api.git'

  spec.files = Dir[
    'LICENSE.txt',
    'README.md',
    'lib/**/*.rb',
    'sig/**/*.rbs',
  ]

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { File.basename(_1) }
  spec.require_paths = ['lib']

  spec.add_dependency 'marcel'
  spec.add_dependency 'net-http'
  spec.add_dependency 'rack'
  spec.add_dependency 'singleton'
  spec.add_dependency 'uri'
end
