# encoding: UTF-8
require File.expand_path('../lib/observables/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'observables'
  s.homepage = 'http://github.com/PlasticLizard/observables'
  s.summary = 'Observable arrays and hashes'
  s.require_path = 'lib'
  #s.default_executable = ''
  s.authors = ['Nathan Stults']
  s.email = ['hereiam@sonic.net']
  #s.executables = ['']
  s.version = Observables::Version
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{bin,examples,lib,rails,test}/**/*") + %w[LICENSE README.rdoc]

  s.add_dependency 'activesupport', '~> 3.0.0'
  s.add_dependency 'i18n'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda', '~> 2.11'
  s.add_development_dependency 'timecop', '~> 0.3.1'
  s.add_development_dependency 'mocha', '~> 0.9.8'
end

