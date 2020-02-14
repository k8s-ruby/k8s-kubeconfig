# frozen-string-literal: true

require_relative 'config_struct'
require_relative 'named_user'
require_relative 'named_cluster'
require_relative 'named_context'

module K8s
  module KubeConfig
    # rubocop:disable Metrics/ClassLength
    # The main root node of the kubeconfig.
    class Root < ConfigStruct
      # @!attribute apiVersion
      #   @return [String]
      attribute :apiVersion, 'v1'
      # @!attribute kind
      #   @return [String]
      attribute :kind, 'Config'
      # @!attribute clusters
      #   @return [Array<NamedCluster>]
      attribute(:clusters, proc { [] })
      # @!attribute contexts
      #   @return [Array<NamedContext>]
      attribute(:contexts, proc { [] })
      # @!attribute users
      #   @return [Array<NamedUser>]
      attribute(:users, proc { [] })
      # @!attribute current_context
      #   @return [String]
      attribute :current_context
      # @!attribute preferences
      #   @return [Hash]
      attribute(:preferences, proc { {} })

      # @see NamedUser
      # @see NamedContext
      # @see NamedCluster
      # @see User
      # @see Cluster
      # @see Context
      # @param data [Hash]
      # @option data apiVersion [String] (defaults to 'v1')
      # @option data kind [String] (defaults to 'Config')
      # @option data clusters [Array<Hash,NamedCluster>]
      # @option data users [Array<Hash,NamedUser>]
      # @option data contexts [Array<Hash,NamedContext>]
      # @option data current_context [String] (can be given as 'current-context')
      # @option data preferences [Hash] (defaults to an empty hash)
      def initialize(data)
        super
      end

      # Build a new K8s::KubeConfig::Root instance containing a single cluster, user and context.
      # @example create a default blank configuration and add a user auth token
      #   K8s::KubeConfig.Root.build(token: 'foo')
      #   { "apiVersion"=>"v1",
      #     "kind"=>"Config",
      #     "clusters"=>[{"name"=>"kubernetes-cluster", "cluster"=>{"server"=>"https://localhost:8080"}}],
      #     "contexts"=>[{"name"=>"k8s@kubernetes-cluster", "context"=>{"cluster"=>"kubernetes-cluster", "user"=>"k8s"}}],
      #     "users"=>[{"name"=>"k8s", "user"=>{"token"=>"foo"}}],
      #     "current-context"=>"k8s@kubernetes-cluster" }
      # @see User
      # @see Cluster
      # @param user [String] username
      # @param cluster [String] cluster name
      # @param context [String] context name
      # @param server [String] server address
      # @param options extra user/cluster options, passed to the Cluster and User creation methods
      def self.build(user: 'k8s', cluster: 'kubernetes-cluster', context: "#{user}@#{cluster}", server: 'https://localhost:8080', **options)
        new(
          current_context: context,
          users: [NamedUser.new(name: user, user: options.merge(ignore_unknown: true))],
          clusters: [NamedCluster.new(name: cluster, cluster: { ignore_unknown: true, server: server }.merge(options))],
          contexts: [NamedContext.new(name: context, context: { cluster: cluster, user: user }.merge(options))]
        )
      end

      # @param data [Array<Hash,NamedCluster>]
      def clusters=(data)
        @clusters = Array(data&.map { |d| d.is_a?(NamedCluster) ? d : NamedCluster.new(d.merge(config_path: @config_path)) })
      end

      # @param data [Array<Hash,NamedContext>]
      def contexts=(data)
        @contexts = Array(data&.map { |d| d.is_a?(NamedContext) ? d : NamedContext.new(d.merge(config_path: @config_path)) })
      end

      # @param data [Array<Hash,NamedUser>]
      def users=(data)
        @users = Array(data&.map { |d| d.is_a?(NamedUser) ? d : NamedUser.new(d.merge(config_path: @config_path)) })
      end

      # Find a named cluster by name
      # @param name [String] defaults to current context cluster name
      # @return [NamedCluster,NilClass]
      def named_cluster(name = context&.cluster)
        return nil if name.nil?

        clusters.find { |c| c.name == name }
      end

      # Find a cluster by name
      # @param name [String] defaults to current context cluster name
      # @return [Cluster,NilClass]
      def cluster(name = context&.cluster)
        named_cluster(name)&.cluster
      end

      # Find a named user by name
      # @param name [String] defaults to current context user name
      # @return [NamedUser,NilClass]
      def named_user(name = context&.user)
        return nil if name.nil?

        users.find { |c| c.name == name }
      end

      # Find a user by name
      # @param name [String] defaults to current context user name
      # @return [User,NilClass]
      def user(name = context&.user)
        named_user(name)&.user
      end

      # @param name [String]
      # @return [NamedContext,NilClass]
      def named_context(name = current_context)
        return nil if name.nil?

        contexts.find { |c| c.name == name }
      end

      # Find a context by name
      # @param name [String] defaults to current-context
      # @return [Context,NilClass]
      def context(name = current_context)
        named_context(name)&.context
      end

      # @see Context
      # @param name [String] context name
      # @param context [Hash] context attributes
      def create_context(name:, **context)
        (contexts << NamedContext.new(name: name, context: context)).last
      end

      # @see Cluster
      # @param name [String] cluster name
      # @param cluster [Hash] cluster attributes
      def create_cluster(name:, **cluster)
        (clusters << NamedCluster.new(name: name, cluster: cluster.merge(config_path: @config_path))).last
      end

      # @see User
      # @param name [String] user name
      def create_user(name:, **user)
        (users << NamedUser.new(name: name, user: user.merge(config_path: @config_path))).last
      end

      # Rename a cluster. References in contexts will be updated.
      # @param old_name [String] old cluster name
      # @param new_name [String] new cluster name
      # @return [String] new name
      # @raise [ArgumentError] when cluster is not found or new name already exists
      def rename_cluster(old_name, new_name)
        named_cluster = clusters.find { |c| c.name == old_name }
        raise ArgumentError, "cluster not found: #{old_name}" unless named_cluster
        raise ArgumentError, "cluster already exists: #{new_name}" if cluster(new_name)

        named_cluster.name = new_name
        contexts.each do |named_context|
          next unless named_context.context.cluster == old_name

          named_context.context.cluster = new_name
        end

        self.current_context = new_name if current_context == old_name

        new_name
      end

      # Rename a user. References in contexts will be updated.
      # @param old_name [String] old user name
      # @param new_name [String] new user name
      # @return [String] new name
      # @raise [ArgumentError] when user is not found or new name already exists
      def rename_user(old_name, new_name)
        named_user = users.find { |u| u.name == old_name }
        raise ArgumentError, "user not found: #{old_name}" unless named_user
        raise ArgumentError, "user already exists: #{new_name}" if user(new_name)

        named_user.name = new_name
        contexts.each do |named_context|
          next unless named_context.context.user == old_name

          named_context.context.user = new_name
        end

        new_name
      end

      # Rename a context.
      # @param old_name [String] old context name
      # @param new_name [String] new context name
      # @return [String] new name
      # @raise [ArgumentError] when context is not found or new name already exists
      def rename_context(old_name, new_name)
        named_context = contexts.find { |c| c.name == old_name }
        raise ArgumentError, "context not found: #{old_name}" unless named_context
        raise ArgumentError, "context already exists: #{new_name}" if context(new_name)

        named_context.name = new_name
      end

      # Merge another kubeconfig into this one, following the merging rules listed in the specifications
      # @param other [Hash,Root]
      # @return [Root] (self)
      def merge!(other)
        other.each do |k, v|
          if v.is_a?(Array)
            v.each do |value|
              send(k) << value.dup unless send("named_#{k[0..-2]}", value.name)
            end
          elsif send(k).nil?
            send("#{k}=", v)
          end
        end

        self
      end
      alias << merge!

      # Create a new instance from this and another kubeconfig, merging as specified in the kubeconfig merge rules specifications
      # @param other [Hash,Root]
      # @return [Root]
      def merge(other)
        dup.merge!(other)
      end
      alias + merge

      # @param flatten [Boolean] read all file references into their data fields
      # @param minify [Boolean] remove all but the active current context
      def to_h(flatten: false, minify: false)
        minify ? minify.to_h(flatten: flatten) : super(flatten: flatten)
      end

      # @param flatten [Boolean] read all file references into their data fields
      # @param minify [Boolean] remove all but the active current context
      # @return [String]
      def to_yaml(flatten: false, minify: false)
        minify ? self.minify.to_yaml(flatten: flatten) : super(flatten: flatten)
      end

      # Remove everything but the values relevant for current context
      # @return [Root] self after modification
      # @raise [RuntimeError] if current_context is unset
      def minify!
        raise 'current_context is nil' if current_context.nil?

        contexts.replace([named_context])
        clusters.replace([named_cluster])
        users.replace([named_user])

        self
      end

      # Create a new instance that contains only the active current context, like `kubectl config --minify`
      # @return [Root]
      def minify
        dup.minify!
      end

      # Writes the YAML representation into a file
      # @param flatten [Boolean] read all file references into their data fields
      # @param minify [Boolean] remove all but the active current context
      # @param path [String] file path
      def write(path, flatten: false, minify: false)
        File.write(path, to_yaml(flatten: flatten, minify: minify))
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
