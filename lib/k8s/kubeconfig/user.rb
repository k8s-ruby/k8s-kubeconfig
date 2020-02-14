# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'user_exec'
require_relative 'named_user_auth_provider'

module K8s
  module KubeConfig
    # @see NamedUser
    class User < ConfigStruct
      # @!attribute auth_provider
      #   @return [NamedUserAuthProvider]
      attribute :auth_provider
      # @!attribute client_certificate
      #   @return [String] Absolute or relative path to client certificate file
      attribute :client_certificate
      # @!attribute client_certificate_data
      #   @return [String] Base64 encoded client certificate data
      attribute :client_certificate_data
      # @!attribute client_key
      #   @return [String] Absolute or relative path to client key file
      attribute :client_key
      # @!attribute client_certificate_data
      #   @return [String] Base64 encoded client key data
      attribute :client_key_data
      # @!attribute username
      #   @return [String]
      attribute :username
      # @!attribute password
      #   @return [String]
      attribute :password
      # @!attribute token
      #   @return [String]
      attribute :token
      # @!attribute exec
      #   @return [UserExec] exec authentication plugin settings
      attribute :exec

      # @return [String] name inherited from NamedUser
      attr_reader :name

      # @see NamedUserAuthProvider
      # @see UserExec
      # @param data [Hash]
      # @option data name [String] name inherited from NamedUser
      # @option data client_certificate [String] client certificate file path
      # @option data client_certificate_data [String] base64 encoded client certificate
      # @option data client_certificate_data_raw [String] plain text client certificate
      # @option data client_key [String] client key file path
      # @option data client_key_data [String] base64 encoded client key
      # @option data client_key_data_raw [String] plain text client key
      # @option data username [String] username for basic auth
      # @option data password [String] password for basic auth
      # @option data token [String] bearer authentication token
      # @option data auth_provider [Hash,NamedUserAuthProvider] auth provider authentication settings
      # @option data exec [Hash,UserExec] exec authentication settings
      def initialize(data)
        @name = data['name'] || data[:name]
        super(data.reject { |k, _v| k == 'name' || k == :name })
      end

      # @return [String] client_certificate_data base64 encoded. If unset and client_certificate path is set, reads from the file.
      def client_certificate_data
        return @client_certificate_data if @client_certificate_data
        return nil unless client_certificate

        in_config_path do
          Base64.strict_encode64(File.read(client_certificate))
        end
      end

      # @return [String] raw base64 decoded client_certificate_data
      def client_certificate_data_raw
        Base64.decode64(client_certificate_data)
      end

      # @param cert_data [String] raw client_certificate_data
      def client_certificate_data_raw=(cert_data)
        self.client_certificate_data = Base64.strict_encode64(cert_data)
      end

      # @return [String] client_key_data base64 encoded. If unset and client_key path is set, reads from the file.
      def client_key_data
        return @client_key_data if @client_key_data
        return nil unless client_key

        in_config_path do
          Base64.strict_encode64(File.read(client_key))
        end
      end

      # @return [String] raw base64 decoded client_key_data
      def client_key_data_raw
        Base64.decode64(client_key_data)
      end

      # @param key_data [String] raw client_key_data
      def client_key_data_raw=(key_data)
        self.client_key_data = Base64.strict_encode64(key_data)
      end

      # @param data [Hash,UserExec]
      def exec=(data)
        @exec = data.is_a?(UserExec) ? data : UserExec.new(data.merge(config_path: @config_path))
      end

      # @param data [Hash,NamedUserAuthProvider]
      def auth_provider=(data)
        @auth_provider = data.is_a?(NamedUserAuthProvider) ? data : NamedUserAuthProvider.new(data.merge(user: self, config_path: @config_path))
      end

      # @return auth_headers [Hash]
      def headers
        if exec
          exec.call
        elsif auth_provider
          auth_provider.handler.call
        elsif token
          { 'Authentication' => "Bearer #{token}" }
        else
          {}
        end
      end
    end
  end
end
