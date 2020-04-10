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

      alias include? key?
      alias includes? key?

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

      def get(key)
        const_get conv_key(key)
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
