# frozen_string_literal: true

root = File.expand_path('..', __FILE__)
lib = File.expand_path('lib', root)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proto/meta'

Gem::Specification.new do |spec|
  spec.name          = 'proto'
  spec.version       = Proto::VERSION
  spec.authors       = Proto::AUTHORS
  spec.email         = Proto::EMAIL
  spec.description   = Proto::DESCRIPTION
  spec.summary       = Proto::SUMMARY
  spec.homepage      = 'http://nan.com'
  spec.license       = 'MIT'

  ignores = File.readlines('.gitignore').grep(/\S+/).map(&:chomp)
  spec.files = Dir['**/*'].reject do |f|
    File.directory?(f) || ignores.any? { |i| File.fnmatch(i, f) }
  end
  spec.files += ['.gitignore']

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'bindata', '~> 2.4.1'
  spec.add_dependency 'text-table', '~> 1.2.4'

  spec.add_development_dependency 'bundler', '~> 1.13.7'
  spec.add_development_dependency 'rake', '~> 12.0.0'
  spec.add_development_dependency 'rubocop', '~> 0.46.0'
end
