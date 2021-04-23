# frozen_string_literal: true

module FatherlyAdvice
  module JsonWebToken
    module EntryMixin
      def matches?(other_name)
        name == other_name.to_s.downcase
      end

      def <=>(other)
        to_s <=> other.to_s
      end

      def inspect
        format '#<%s name=%s>', self.class.name, name.inspect
      end

      alias to_s inspect

      private

      def get_env(key, default = nil)
        Env.get(build_full_key(key), default)
      end

      def build_full_key(key)
        ['oauth2', prefix.blank? ? nil : prefix, key].compact.map(&:to_s).join('_')
      end
    end

    class << self
      DEFAULT_TIMEOUT = 2 unless const_defined?(:DEFAULT_TIMEOUT)

      def default_request_options
        @default_request_options ||= {
          connect_timeout: DEFAULT_TIMEOUT,
          read_timeout: DEFAULT_TIMEOUT,
          write_timeout: DEFAULT_TIMEOUT,
          headers: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          },
          ssl_verify_peer: true
        }
      end

      def request(meth, path, options = {})
        options = default_request_options.merge options
        Excon.send meth, path, options
      end

      def local_cache
        @local_cache ||= {}
      end

      def shared_cache_options
        {
          expires_in: 60.minutes,
          url: WebServer.redis_url,
          namespace: format('%s:jwt:cache', WebServer.app_name),
          race_condition_ttl: 3.seconds
        }
      end

      def shared_cache
        @shared_cache ||= ActiveSupport::Cache::RedisCacheStore.new shared_cache_options
      end

      def clear_cache
        [local_cache, shared_cache].map(&:clear)
      end
    end
  end
end

require_relative 'json_web_token/client'
require_relative 'json_web_token/server'
