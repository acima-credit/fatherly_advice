# frozen_string_literal: true

module FatherlyAdvice
  class Env
    class << self
      def key?(name)
        ::ENV.key? conv_key(name)
      end

      def get(name, default = nil)
        return default unless key?(name)

        value = ::ENV[conv_key(name)]
        block_given? ? yield(value) : value
      end

      alias [] get

      def get!(name, &blk)
        raise Error, "Missing ENV['#{conv_key(name)}']" unless key?(name)

        get name, &blk
      end

      def get_list(name, defaults = nil)
        return defaults unless key?(name)

        value = ::ENV[conv_key(name)].to_s.split(',')
        block_given? ? yield(value) : value
      end

      def get_list!(name, &blk)
        raise Error, "Missing ENV['#{conv_key(name)}']" unless key?(name)

        get_list name, &blk
      end

      def enabled?(name, default = false)
        return default unless key?(name)

        get(name).to_s.casecmp('true').zero?
      end

      def disabled?(name, default = false)
        return default unless key?(name)

        get(name).to_s.casecmp('false').zero?
      end

      def to_i(name, default = nil)
        return default unless key?(name)

        get(name).to_i
      end

      def to_f(name, default = nil)
        return default unless key?(name)

        get(name).to_f
      end

      def check_present!(*names)
        missing = names.reject(&method(:key?)).map(&method(:conv_key))
        return true if missing.empty?

        raise Error, "Missing key(s) : #{missing.inspect}"
      end

      def respond_to_missing?(_name, _private = false)
        true
      end

      def method_missing(meth, *args, &blk)
        return ENV.send(meth, *args, &blk) if ENV.respond_to?(meth)
        return enabled?(meth[0..-2]) if meth.to_s.end_with?('?')
        return get!(meth[0..-2], &blk) if meth.to_s.end_with?('!')

        get(meth || super, &blk)
      end

      private

      def conv_key(key)
        key.to_s.upcase
      end
    end
  end
  SiteSettings = Env
end
