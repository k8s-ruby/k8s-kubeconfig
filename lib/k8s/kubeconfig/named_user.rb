# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'user'

module K8s
  module KubeConfig
    # @see User
    class NamedUser < ConfigStruct
      # @!attribute name
      #   @return [String]
      attribute :name
      # @!attribute user
      #   @return [User]
      attribute :user

      # @see User
      # @param data [Hash]
      # @option data user [Hash,User]
      # @option data name [String]
      def initialize(data)
        super
      end

      # @param data [Hash,User]
      def user=(data)
        @user = data.is_a?(Hash) ? User.new(data.merge(name: name)) : data
      end
    end
  end
end
