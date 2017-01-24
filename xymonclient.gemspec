# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xymonclient/version'

Gem::Specification.new do |spec|
  spec.name          = 'xymonclient'
  spec.version       = XymonClient::VERSION
  spec.authors       = ['David Chauviere']
  spec.email         = ['david.chauviere@orange.com']

  spec.summary       = 'Xymon client library'
  spec.description   = 'Interact with Xymon server, send status, ack, ' \
                       'enable/disable'
  spec.homepage      = 'https://github.com/Orange-OpenSource/ruby-xymonclient'
  spec.licenses      = ['Apache-2.0']

  spec.files         = Dir['lib/**/*.rb'] + Dir['bin/*'] + Dir['spec/**/*.rb'] \
                       + Dir['[A-Z]*'] + Dir['*.md']
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '= 0.40'
  spec.add_development_dependency 'simplecov', '~> 0.12.0'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
end
