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
        Diplomat.configuration.url = consul_url
        @lock_key = options[:consul_lock_key] || 'deployment/locked'
        @session_id = nil
      end
      attr_reader :lock_key

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
        r = Diplomat::Kv.get(lock_key)
        !!(Base64.decode64(r.Value) =~ /\A["'](t(rue)?|1|y(es)?)["']\z/)
      rescue => e
        # in case of 404
        if e.message.include?('404')
          return false
        else
          raise e
        end
      end

      def create_session
        logger.debug "Session request: #{session_request.inspect}"
        @session_id = Diplomat::Session.create(session_request)
      end

      def delete_session
        with_session {
          Diplomat::Session.destroy(@session_id)
        }
        @session_id = nil
      end

      def lock
        with_session { Diplomat::Lock.acquire(lock_key, @session_id) }
      end

      def unlock
        with_session { Diplomat::Lock.release(lock_key, @session_id) }
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
