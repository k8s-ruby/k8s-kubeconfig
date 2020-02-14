# frozen-string-literal: true

require_relative 'config_struct'

module K8s
  module KubeConfig
    # Struct for UserExec's environment variable list
    class UserExecEnv < ConfigStruct
      # @!attribute name
      #   @return [String]
      attribute :name
      # @!attribute value
      #   @return [String]
      attribute :value

      # @param data [Hash]
      # @option data name [String]
      # @option data value [String]
      def initialize(data)
        super
      end
    end
  end
end
