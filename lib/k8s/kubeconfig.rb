# frozen-string-literal: true

require 'time'
require 'yaml'

require_relative 'kubeconfig/version'
require_relative 'kubeconfig/root'

module K8s
  # A parser for Kubernetes client configuration files.
  #
  # See https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
  # for more information on kubeconfig files.
  module KubeConfig
    DEFAULT_LOCATIONS = [
      File.join(Dir.home, '.kube', 'config').freeze,
      '/etc/kubernetes/admin.conf',
      '/etc/kubernetes/kubelet.conf' # usually has restricted access rights
    ].freeze

    # @todo figure out how to document inherited initializer options
    # @todo split into multiple files
    # @todo create readme with examples
    # @todo write specs

    # @param data [Hash, NilClass]
    # @option data (see Root#initialize)
    # @return [Root]
    def self.new(data = {})
      Root.new(data)
    end

    # @see Root#build
    # @example create a default blank configuration and add a user auth token
    #   K8s::KubeConfig.build(token: 'foo')
    #   { "apiVersion"=>"v1",
    #     "kind"=>"Config",
    #     "clusters"=>[{"name"=>"kubernetes-cluster", "cluster"=>{"server"=>"https://localhost:8080"}}],
    #     "contexts"=>[{"name"=>"k8s@kubernetes-cluster", "context"=>{"cluster"=>"kubernetes-cluster", "user"=>"k8s"}}],
    #     "users"=>[{"name"=>"k8s", "user"=>{"token"=>"foo"}}],
    #     "current-context"=>"k8s@kubernetes-cluster" }
    # @param options
    # @param (see Root.build)
    # @return [Root]
    def self.build(**options)
      Root.build(**{ config_path: Dir.pwd }.merge(options))
    end

    # Loads or generates a configuration using the default locations.
    #
    # Look-up order is:
    #  - KUBECONFIG environment variable
    #  - Any of the {KubeConfig::DEFAULT_LOCATIONS} files
    #  - The so called "in cluster config"
    # @return [Root]
    def self.load_default
      return load_env if ENV.key?('KUBECONFIG')

      existing_config = DEFAULT_LOCATIONS.find { |path| File.exist?(path) }
      return load_file(existing_config) if existing_config

      return load_in_cluster if ENV.key?('KUBERNETES_SERVICE_HOST') && ENV.key?('KUBERNETES_SERVICE_PORT_HTTPS')

      nil
    end

    # Load a kubeconfig from a string
    # @param content [String]
    # @return [Root]
    def self.load_string(content, path = nil)
      Root.new({ config_path: path }.merge(YAML.safe_load(content, [Time, DateTime, Date], [], true)))
    end

    # Load a kubeconfig file from a path or multiple paths
    # @param paths [String] files from multiple paths will be merged, see {Root#merge}
    # @return [Root]
    def self.load_file(*paths)
      paths.flatten!
      raise ArgumentError, 'no paths given' if paths.empty?

      paths.map! { |path| File.expand_path(path) }
      root_path = paths.shift
      root = load_string(File.read(root_path), root_path)

      paths.each do |path|
        root.merge!(load_string(path), path)
      end

      root
    end

    # Load and merge the configuration files listed in KUBECONFIG environment variable (colon separated)
    # @return [Root]
    def self.load_env
      raise 'KUBECONFIG environment variable not set' unless ENV.key?('KUBECONFIG')

      load_file(*ENV['KUBECONFIG'].split(':'))
    end

    # Load the so called "in cluster configuration", which is available when running inside a pod.
    # @return [Root]
    def self.load_in_cluster
      raise 'KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT_HTTPS not set' unless ENV.key?('KUBERNETES_SERVICE_HOST') && ENV.key?('KUBERNETES_SERVICE_PORT_HTTPS')

      secrets_root = File.join(ENV['TELEPRESENCE_ROOT'] || '/', 'var/run/secrets/kubernetes.io/serviceaccount')

      ca_file = File.join(secrets_root, 'ca.crt')
      sa_token_file = File.join(secrets_root, 'token')
      sa_token = File.read(sa_token_file) if File.exist?(sa_token_file)

      build(
        server: "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT_HTTPS']}",
        certificate_authority: ca_file,
        token: sa_token
      )
    end
  end
end
