# frozen_string_literal: true

module FatherlyAdvice
  class Scrubber
    attr_reader :keys

    def initialize(*keys)
      @keys = keys.map(&:to_s).freeze
    end

    def scrub_keys(hsh, *keys)
      keys.each { |key| scrub hsh[key] }
      hsh
    end

    def scrub_hash(hsh)
      return unless hsh.is_a?(Hash)

      hsh.each do |k, v|
        case v
        when Hash
          scrub_hash v
        when Enumerable
          scrub_enumerable v
        when String, Numeric
          scrub_pair hsh, k, v
        end
      end

      hsh
    end

    def scrub_enumerable(ary)
      return unless ary.is_a? Enumerable

      ary.each { |x| scrub_hash x }
    end

    def scrub_pair(hsh, k, v)
      return unless keys.include? k.to_s

      hsh[k] = '*' * v.to_s.size
    end
  end
end
