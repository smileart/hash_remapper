# frozen_string_literal: true
# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hash_remapper'

Gem::Specification.new do |spec|
  spec.name          = 'hash_remapper'
  spec.version       = HashRemapper::VERSION
  spec.authors       = ['Serge Bedzhyk']
  spec.email         = 'smileart21@gmail.com'

  spec.summary       = 'A little lib which maps original keys to the new ones'
  spec.description   = 'A little lib which maps original keys to the new ones and more'
  spec.homepage      = 'https://rubygems.org/gems/hash_remapper'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',        '~> 1.16'
  spec.add_development_dependency 'byebug',         '~> 9.1'
  spec.add_development_dependency 'inch',           '~> 0.7'
  spec.add_development_dependency 'letters',        '~> 0.4'
  spec.add_development_dependency 'rake',           '~> 12.2'
  spec.add_development_dependency 'rspec',          '~> 3.7'
  spec.add_development_dependency 'rubocop',        '~> 0.51'
  spec.add_development_dependency 'rubygems-tasks', '~> 0.2'
  spec.add_development_dependency 'simplecov',      '~> 0.15'
  spec.add_development_dependency 'yard',           '~> 0.8'
end
