# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'context'

module K8s
  module KubeConfig
    # @see Context
    class NamedContext < ConfigStruct
      # @!attribute name
      #   @return [String]
      attribute :name
      # @!attribute context
      #   @return [Context]
      attribute :context

      # @see Context
      # @param data [Hash]
      # @option data user [Hash,Context]
      # @option data name [String]
      def initialize(data)
        super
      end

      # @param data [Hash,Context]
      def context=(data)
        @context = data.is_a?(Hash) ? Context.new(data) : data
      end
    end
  end
end
