# frozen-string-literal: true

require_relative 'config_struct'

module K8s
  module KubeConfig
    # @see NamedContext
    class Context < ConfigStruct
      # @!attribute cluster
      #   @return [String]
      attribute :cluster
      # @!attribute user
      #   @return [String]
      attribute :user
      # @!attribute namespace
      #   @return [String,NilClass]
      attribute :namespace

      # @param data [Hash]
      # @option data cluster [String] cluster name
      # @option data user [String] user name
      # @option data namespace [String]
      def intialize(data)
        super
      end
    end
  end
end
