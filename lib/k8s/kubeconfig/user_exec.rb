# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'user_exec_env'
require 'open3'

module K8s
  module KubeConfig
    # Exec authentication settings
    class UserExec < ConfigStruct
      # @!attribute apiVersion
      #   @return [String]
      attribute :apiVersion, 'client.authentication.k8s.io/v1beta1'
      # @!attribute command
      #   @return [String]
      attribute :command
      # @!attribute env
      #   @return [Array<UserExecEnv>]
      attribute :env
      # @!attribute args
      #   @return [Array<String>]
      attribute :args

      # @param data [Hash]
      # @option data apiVersion [String]
      # @option data command [String]
      # @option data env [Array<Hash,UserExecEnv>]
      # @option data args [Array<String>]
      def initialize(data)
        super
      end

      # @param data [Array<Hash,UserExecEnv>]
      def env=(data)
        @env = data.map { |d| d.is_a?(Hash) ? UserExecEnv.new(d) : d }
      end

      def call
        in_config_path do
          stdout_str, error_str, status = Open3.capture3(Array(env).map { |e| [e.name, e.value] }.to_h, command, *args)
          raise "exec-authentication command failed: #{error_str}" unless status.success?

          { 'Authentication' => "Bearer #{stdout_str.strip}" }
        end
      end
    end
  end
end
