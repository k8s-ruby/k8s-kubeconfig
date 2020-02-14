# frozen-string-literal: true

module K8s
  module KubeConfig
    # A simple form object class that works a bit like OpenStruct.
    #
    # @example Attributes can be defined using the "attribute" -method
    #   class Foo < ConfigStruct
    #     attribute :bar
    #     attribute :kind, 'Config'
    #   end
    #   Foo.new(bar: 'abcd').bar # => 'abcd'
    #   Foo.new(bar: 'abcd').kind # => 'Config'
    class ConfigStruct
      include Enumerable

      # @return [Hash<Symbol => Object>] list of attributes specified for this struct (key is attribute name, value is default value)
      def self.attributes
        @attributes ||= {}
      end

      # @param name [Symbol]
      def self.attribute(name, default = nil)
        attributes[name] = default
        attr_accessor name
      end
      private_class_method :attribute

      # Can be initialized from a hash having keys the same as the listed
      # attribute names or dashed names such as "cluster-context"
      # @param data [Hash]
      # @option data ignore_unknown [Boolean] don't raise for unknown attributes
      # @option data ignore_unknown [Boolean] don't raise for unknown attributes
      # @raise [ArgumentError] for unknown keys when ignore_unknown is false
      def initialize(data)
        ignore_unknown = data.delete(:ignore_unknown)
        @config_path = data.delete(:config_path)
        set_defaults
        update_attributes(data, ignore_unknown: ignore_unknown)
      end

      # @yieldparam [Symbol] key
      # @yieldparam [Object] value
      def each
        self.class.attributes.keys.each do |k|
          yield k, send(k)
        end
      end

      # Create an independent duplicate
      def dup
        self.class.new(
          self.class.attributes.keys.each_with_object({}) do |k, result|
            val = send(k)
            next if val.nil? || (val.respond_to?(:empty?) && val.empty?)

            result[k] = val.is_a?(Array) ? val.map(&:dup) : val.dup
          end
        )
      end

      # @param flatten [Boolean] Read all file references into their data fields
      # @return [Hash]
      def to_h(flatten: false)
        self.class.attributes.keys.each_with_object({}) do |key, result|
          new_value = hashify(send(key), flatten: flatten)
          next if new_value.nil? || (new_value.respond_to?(:empty?) && new_value.empty?)

          result[key.to_s.tr('_', '-')] = new_value
        end
      end

      # @param flatten [Boolean] read all file references into their data fields
      # @return [String]
      def to_yaml(flatten: false)
        YAML.dump(to_h(flatten: flatten))
      end

      # Like `kubectl config --flatten`, returns a version where file references are read into their data fields
      # @return [Object] self after file references are flattened
      def flatten!
        self.class.attributes.keys.select { |k| k.end_with?('_data') }.each do |data_attr|
          reference_attr = data_attr[/(.+?)_data$/, 1]
          value = send(data_attr)
          next if value.nil?

          send("#{data_attr}=", value)
          send("#{reference_attr})", nil)
        end

        self
      end

      # @return [Object] a copy of the object with flattened file references
      def flatten
        dup.flatten!
      end

      private

      def in_config_path(&block)
        return yield unless @config_path

        if File.directory?(@config_path)
          Dir.chdir(@config_path, &block)
        else
          Dir.chdir(File.dirname(@config_path), &block)
        end
      end

      def hashify(value, flatten: false)
        case value
        when Array
          value.map { |v| hashify(v, flatten: flatten) }
        when Hash
          Hash[value.map { |k, v| [k, hashify(v, flatten: flatten)] }]
        when self.class
          flatten ? flatten.to_h : to_h
        else
          value.respond_to?(:to_h) ? value.to_h : value
        end
      end

      def set_defaults
        self.class.attributes.each do |key, default_value|
          next if default_value.nil?

          send("#{key}=", default_value.respond_to?(:call) ? default_value.call(key) : default_value)
        end
      end

      def update_attributes(data, ignore_unknown: false)
        data.each do |key, value|
          transformed_key = key.to_s.tr('-', '_').to_sym

          unless self.class.attributes.key?(transformed_key)
            next if ignore_unknown

            raise ArgumentError, "unknown attribute #{key}"
          end

          send "#{transformed_key}=", value
        end
      end
    end
  end
end
