require 'uri'
require 'base64'

require 'consul/client'

namespace :consul_kv_lock do
  class SSHKittyLogger
    def initialize
      @coordinator = SSHKit::Coordinator.new('localhost')
    end

    %w(debug info warn error fatal).each do |ll|
      define_method(ll) do |str|
        @coordinator.each do
          run_locally { self.send(ll, "[consul-client] #{str}") }
        end
      end
    end
  end

  def client
    @_client ||= begin
                   consul = URI.parse(fetch(:consul_url))
                   Consul::Client.v1.http(host: consul.host, port: consul.port, logger: SSHKittyLogger.new)
                 end
  end

  def lock_key
    fetch(:consul_lock_key)
  end

  def locked?
    r = client.get("/kv/#{lock_key}")
    !!(Base64.decode64(r[0]['Value']) =~ /\A["'](t(rue)?|1|y(es)?)["']\z/)
  rescue Consul::Client::ResponseException => e
    # in case of 404
    if e.message.include?('404')
      return false
    else
      raise e
    end
  end

  task :check_lock do
    if locked?
      fail("Deployment is locked!")
    end
  end

  task :lock do
    run_locally do
      info("Setting lock to #{fetch(:consul_url)}")
      client.put("/kv/#{lock_key}", "true")
    end
  end

  task :unlock do
    run_locally do
      info("Deleting lock from #{fetch(:consul_url)}")
      client.put("/kv/#{lock_key}", "false")
    end
  end
end

before 'deploy:starting', 'consul_kv_lock:lock'
before 'consul_kv_lock:lock', 'consul_kv_lock:check_lock'
after  'deploy:finished', 'consul_kv_lock:unlock'
after  'deploy:failed', 'consul_kv_lock:unlock'

namespace :load do
  task :defaults do

    set :consul_url,      -> { 'http://localhost:8500' }
    set :consul_lock_key, -> { 'deployment/locked' }

  end
end
