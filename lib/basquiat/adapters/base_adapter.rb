module Basquiat
  module Adapters
    module Base
      def initialize
        @options = default_options
        @procs   = {}
        @retries = 0
      end

      # Used to set the options for the adapter. It is merged in
      # to the default_options hash.
      # @param [Hash] opts an adapter dependant hash of options
      def adapter_options(opts)
        deep_merge(opts)
      end

      # Default options for the adapter
      # @return [Hash]
      def default_options
        {}
      end

      def publish
      end

      def subscribe_to
      end

      private

      attr_reader :procs, :options

      def deep_merge(original = options, hash)
        hash.each_pair do |key, value|
          current = original[key]
          if current.is_a?(Hash) && value.is_a?(Hash)
            deep_merge(current, value)
          else
            original[key] = value
          end
        end
      end

      def self.json_encode(object)
        MultiJson.dump(object)
      end

      def self.json_decode(object)
        MultiJson.load(object, symbolize_keys: true)
      rescue
        {}
      end
    end
  end
end
