require "capistrano/framework"
require "capistrano/consul_kv_lock/latch"
require "capistrano/consul_kv_lock/version"

load File.expand_path("../tasks/consul_kv_lock.rake", __FILE__)
