require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/observables/version', __FILE__)

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
end

task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build observables.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install observables-#{Observables::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Observables::Version}"
  sh "git push origin master"
  sh "git push origin v#{Observables::Version}"
  sh "gem push mongo_mapper-#{Observables::Version}.gem"
end

