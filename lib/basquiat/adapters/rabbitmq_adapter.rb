require 'bunny'
require 'delegate'

module Basquiat
  module Adapters
    # The RabbitMQ adapter for Basquiat
    class RabbitMq < Basquiat::Adapters::Base
      using Basquiat::HashRefinements

      # Avoid superclass mismatch errors
      require 'basquiat/adapters/rabbitmq/message'
      require 'basquiat/adapters/rabbitmq/configuration'
      require 'basquiat/adapters/rabbitmq/connection'
      require 'basquiat/adapters/rabbitmq/session'
      require 'basquiat/adapters/rabbitmq/requeue_strategies'

      def base_options
        @configuration ||= Configuration.new
        @configuration.merge_user_options(Basquiat.configuration.adapter_options)
      end

      def subscribe_to(event_name, proc)
        procs[event_name] = proc
      end

      def publish(event, message, persistent: options[:publisher][:persistent], props: {})
        connection.with_network_failure_handler do
          session.publish(event, message, props)
          disconnect unless persistent
        end
      end

      def listen(block: true)
        connection.with_network_failure_handler do
          procs.keys.each { |key| session.bind_queue(key) }
          session.subscribe(block) do |message|
            strategy.run(message) do
              procs[message.routing_key].call(message)
            end
          end
        end
      end

      def reset_connection
        connection.disconnect
        @connection = nil
        @session    = nil
      end

      alias_method :disconnect, :reset_connection

      def strategy
        @strategy ||= @configuration.strategy.new(session)
      end

      def session
        @session ||= Session.new(connection, @configuration.session_options)
      end

      private

      def connection
        @connection ||= Connection.new(@configuration.connection_options)
      end
    end
  end
end
