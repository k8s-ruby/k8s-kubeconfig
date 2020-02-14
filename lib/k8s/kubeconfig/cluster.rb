# frozen-string-literal: true

require_relative 'config_struct'
require 'uri'
require 'base64'

module K8s
  module KubeConfig
    # @see NamedCluster
    class Cluster < ConfigStruct
      # @!attribute certificate_authority
      #   @return [String] Path to certificate authority file
      attribute :certificate_authority
      # @!attribute certificate_authority_data
      #   @return [String] Base64-encoded certificate authority data
      attribute :certificate_authority_data
      # @!attribute server
      #   @return [String] Server API address
      attribute :server
      # @!attribute insecure_skip_tls_verify
      #   @return [Boolean]
      attribute :insecure_skip_tls_verify

      # @!attribute certificate_authority_data_raw
      #   @return [String] Base64-decoded raw certificate_authority data

      # @param data [Hash]
      # @option data certificate_authority [String] CA file path
      # @option data certificate_authority_data [String] Base64 encoded ca
      # @option data certificate_authority_data_raw [String] Plaintext ca
      # @option data server [String] Cluster api address
      # @option data insecure_skip_tls_verify [Boolean]
      def initialize(data)
        super
      end

      # @return [String] certificate_authority_data base64 encoded. if unset and certificate_authority path is set, reads from the file
      def certificate_authority_data
        return @certificate_authority_data if @certificate_authority_data
        return nil unless certificate_authority

        # Not cached to allow underlying file to change
        in_config_path do
          Base64.strict_encode64(File.read(certificate_authority))
        end
      end

      # @return [String] raw certificate authority data
      def certificate_authority_data_raw
        Base64.decode64(certificate_authority_data)
      end

      # @param ca_data [String] raw certificate authority data
      def certificate_authority_data_raw=(ca_data)
        self.certificate_authority_data = Base64.strict_encode64(ca_data)
      end

      # @return [URI] parsed server address URI
      def uri
        @uri ||= URI.parse(server)
      end
    end
  end
end
