module Capistrano
  module ConsulKvLock
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

    class Latch
      def self.set_instance(consul_url, options={})
        @_instance ||= new(consul_url, options)
        logger.debug "Registered latch instance: #{@_instance.inspect}"
        @_instance
      end

      def self.instance
        @_instance
      end

      def self.logger
        @_logger ||= SSHKittyLogger.new
      end

      def initialize(consul_url, options={})
        @client = begin
                   consul = URI.parse(consul_url)
                   Consul::Client.v1.http(host: consul.host, port: consul.port, logger: logger)
                  end
        @lock_key = options[:consul_lock_key] || 'deployment/locked'
        @session_id = nil
      end
      attr_reader :client, :lock_key

      def logger
        self.class.logger
      end

      def session_request
        {
          "LockDelay" => 15,
          "Name" => "lock-for-#{lock_key.tr("/", "-")}",
        }
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

      def create_session
        logger.debug "Session request: #{session_request.inspect}"
        r = client.put("/session/create", session_request)
        @session_id = r['ID']
      end

      def delete_session
        with_session {
          client.put("/session/destroy/#{@session_id}", "")
        }
        @session_id = nil
      end

      def lock
        with_session { client.put("/kv/#{lock_key}?acquire=#{@session_id}", "true") }
      end

      def unlock
        with_session { client.put("/kv/#{lock_key}?release=#{@session_id}", "false") }
      end

      private
      def with_session &blk
        return false unless @session_id
        blk.call
        return true
      end
    end
  end
end
