# frozen-string-literal: true

module K8s
  module KubeConfig
    # Namespace for auth provider handlers
    module AuthProvider
      # Abstract
      class Base < ConfigStruct
        attr_reader :user

        def initialize(data)
          @user = data['user'] || data[:user]
          super(data.reject { |k, _v| k == 'user' || k == :user })
        end

        # @abstract should return http request headers
        def call
          raise NotImplementedError
        end
      end
    end
  end
end

Dir[File.join(__dir__, 'auth_provider', '*.rb')].each { |f| require f }
