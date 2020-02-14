# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'cluster'

module K8s
  module KubeConfig
    # @see Cluster
    class NamedCluster < ConfigStruct
      # @!attribute name
      #   @return [String]
      attribute :name
      # @!attribute cluster
      #   @return [Cluster]
      attribute :cluster

      # @see Cluster
      # @param data [Hash]
      # @option data cluster [Hash,Cluster]
      # @option data name [String]
      def initialize(data)
        super
      end

      # @param data [Hash,Cluster]
      def cluster=(data)
        @cluster = data.is_a?(Hash) ? Cluster.new(data) : data
      end
    end
  end
end
