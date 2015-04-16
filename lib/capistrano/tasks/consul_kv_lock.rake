require 'uri'
require 'base64'

require 'consul/client'

namespace :consul_kv_lock do
  def client
    @_client ||= begin
                   consul = URI.parse(fetch(:consul_url))
                   Consul::Client.v1.http(host: consul.host, port: consul.port, logger: Logger.new(STDOUT))
                 end
  end

  def lock_key
    fetch(:consul_lock_key)
  end

  def locked?
    r = client.get("/kv/#{lock_key}")
    !! Base64.decode64(r[0]['Value']) =~ /\A(t(rue)?|1|y(es)?)\z/
  end

  def lock
    client.put("/kv/#{lock_key}", "true")
  end

  def unlock
    client.put("/kv/#{lock_key}", "false")
  end

  task :check_lock do
    if locked?
      fail("Deployment is locked!")
    end
  end

  task :lock do
    lock
  end

  task :unlock do
    unlock
  end
end

before 'deploy:starting', 'consul_kv_lock:lock'
before 'consul_kv_lock:lock', 'consul_kv_lock:check_lock'
after  'deploy:finished', 'consul_kv_lock:unlock'

namespace :load do
  task :defaults do

    set :consul_url,      -> { 'http://localhost:8500' }
    set :consul_lock_key, -> { 'deployment/locked' }

  end
end
