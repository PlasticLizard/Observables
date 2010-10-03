require 'rubygems'

base_dir = File.dirname(__FILE__)
[
  'base',
  'array_watcher',
  'hash_watcher',
  'collections',
  'version'
].each {|req| require File.join(base_dir,'observables',req)}

Dir[File.join(base_dir,"observables","extensions","*.rb")].each {|ext|require ext}

module Observables
end