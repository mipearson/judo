require 'rubygems'
require 'erb'
require 'active_support'
require 'aws'
require 'socket'
require 'fileutils'
require 'yaml'
require 'json'
require 'pp'
require 'tempfile'

class JudoError < RuntimeError ; end
class JudoInvalid < RuntimeError ; end

require_relative 'extras/benchmark'
require_relative 'judo/util'
require_relative 'judo/base'
require_relative 'judo/group'
require_relative 'judo/server'
require_relative 'judo/snapshot'
require_relative 'judo/patch'
require_relative 'judo/keypair'

if ENV['BENCH_EVERYTHING']
  ENV['BENCH_METHODS'] = '1'
  
  # Find out how to automatically grab all classes..
  [Judo::Base, Judo::Group, Judo::Server, Judo::Snapshot].each do |klass|
  #[Judo::Server].each do |klass|

    klass.class_eval do
      extend Extras::Benchmark
      bench_all_methods
    end
  end
    
  # 
  # Judo.constants.each do |constant|
  #   eval "
  #     if Judo::#{constant}.is_a? Class
  #     Judo::#{constant}.class_eval do
  #       puts constant
  #       extend Extras::Benchmark
  #       bench_all_methods
  #     end
  #   end
  #   "
  # end
end
    