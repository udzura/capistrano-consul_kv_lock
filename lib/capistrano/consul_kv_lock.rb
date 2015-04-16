require 'capistrano/framework'
load File.expand_path("../tasks/consul_kv_lock.rake", __FILE__)

module Capistrano
  module ConsulKvLock
    # Your code goes here...
  end
end

require "capistrano/consul_kv_lock/version"
