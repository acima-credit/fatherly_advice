# frozen_string_literal: true

module FatherlyAdvice
  module Enums
    module EnumMixin
      def add(key, value = key)
        key = conv_key key
        return false if include?(key)

        value = conv_value value
        entries.add key
        define_singleton_method(key.downcase) { get key }
        const_set key, value
      end

      def keys
        entries.to_a
      end

      def key?(key)
        entries.include? conv_key(key)
      end

      def include?(value)
        values.include? conv_value(value)
      end

      alias includes? include?

      def get(key)
        return nil unless key?(key)

        const_get conv_key(key)
      end

      def get!(key)
        found = get key
        raise "unknown key [#{key}]" if found.nil?

        found
      end

      def value!(value)
        found = include?(value) ? conv_value(value) : false
        raise "unknown value [#{value}]" unless found

        found
      end

      def values
        entries.map { |key| get key }
      end

      def each
        entries.each { |key| yield key, get(key) }
      end

      def to_h
        entries.each_with_object({}) { |key, hsh| hsh[key] = get key }
      end

      alias to_hash to_h

      private

      def entries
        @entries ||= Set.new
      end

      def conv_key(key)
        key.to_s.upcase
      end

      def conv_value(value)
        value.to_s.downcase
      end
    end

    module_function

    def build(*args)
      Module.new.tap do |mod|
        mod.extend EnumMixin
        add_entries mod, args
      end
    end

    def add_entries(mod, args)
      args.each do |arg|
        case arg
        when String, Symbol
          mod.add arg, arg
        when Hash
          arg.each { |k, v| mod.add k, v }
        end
      end
    end
  end
end
