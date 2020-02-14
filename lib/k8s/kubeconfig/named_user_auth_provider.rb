# frozen-string-literal: true

require 'ostruct'

# rubocop:disable Lint/HandleExceptions
begin
  require 'recursive-open-struct'
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

require_relative 'config_struct'
require_relative 'auth_provider'

module K8s
  module KubeConfig
    # User authentication provider settings
    class NamedUserAuthProvider < ConfigStruct
      # @!attribute config
      #   @return [Object]
      attribute :config
      # @!attribute name
      #   @return [String]
      attribute :name

      attr_reader :user

      # An auth provider handler can be created as
      # `K8s::KubeConfig::*AuthProvider`, for example
      # `K8s::KubeConfig::OIDCUserAuthProvider`
      # @param data [Hash]
      # @option data config [Hash,Object]
      # @option data user [User]
      # @option data name [String]
      def initialize(data)
        @user = data['user'] || data[:user]
        # forced reorder so config= is called last
        super(name: data['name'] || data[:name], config: data['config'] || data[:config])
      end

      # @param data [Hash,Object]
      # @return [Object]
      def config=(data)
        @config = data.is_a?(Hash) ? auth_provider_handler_class.new(data.merge(user: user, config_path: @config_path)) : data
      end

      # @method handler
      # @return [Object] user auth provider handler
      alias handler config

      private

      def auth_provider_handler_class
        klass = K8s::KubeConfig::AuthProvider.constants.find do |c|
          c.to_s.downcase == name.downcase.gsub(/[^a-z0-9]/, '').to_s
        end
        return K8s::KubeConfig::AuthProvider.const_get(klass) if klass

        Object.const_defined?(:RecursiveOpenStruct) ? RecursiveOpenStruct : OpenStruct
      end
    end
  end
end
