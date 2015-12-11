# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mkghrepo/version'

Gem::Specification.new do |spec|
  spec.name        = 'mkghrepo'
  spec.version     = Mkghrepo::VERSION
  spec.executables << 'mkghrepo'
  spec.authors     = ['Fabio Rapposelli']
  spec.email       = ['fabio@rapposelli.org']
  spec.description = 'mkghrepo is a tool to facilitate mass repository creation'
  spec.summary     = 'mkghrepo is a tool to facilitate mass repository creation'
  spec.homepage    = 'https://github.com/frapposelli/mkghrepo'
  spec.license     = 'APL2'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'octokit', '~> 4.0'
  spec.add_runtime_dependency 'slop', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
end
