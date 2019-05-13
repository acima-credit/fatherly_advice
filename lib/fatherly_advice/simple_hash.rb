# frozen_string_literal: true

# From https://localhostdotdev.com/simple_hash/

module FatherlyAdvice
  class SimpleHash < Hash
    class Serializer
      def self.dump(simple_hash)
        return if simple_hash.nil?

        simple_hash.to_h
      end

      def self.load(hash)
        return if hash.nil?

        SimpleHash[hash]
      end
    end

    def initialize(constructor = {})
      raise 'not supported' unless constructor.respond_to?(:to_hash)

      super()
      update(constructor)
      freeze
    end

    def self.[](data)
      super(data).freeze
    end

    def method_missing(method_name, *args, &block)
      if keys.map(&:to_s).include?(method_name.to_s) && args.empty? && block.nil?
        fetch(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      keys.map(&:to_s).include?(method_name.to_s) || super
    end

    def methods
      super + keys.map(&:to_sym)
    end

    def [](key)
      if keys.include?(key.to_s)
        super(key.to_s)
      else
        super(key.to_sym)
      end
    end

    def fetch(key)
      convert(super(key.to_sym) { super(key.to_s) })
    end

    private

    def convert(value)
      if value.is_a?(Hash)
        SimpleHash[value]
      elsif value.is_a?(Array)
        value.map { |val| convert(val) }
      else
        value
      end
    end
  end
end
