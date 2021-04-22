# frozen_string_literal: true

module FatherlyAdvice
  module JsonWebToken
    module Client
      class AccessToken
        attr_reader :access_token, :expires_in, :token_type, :scope
        attr_accessor :expiration_time

        def initialize(access_token, expires_in, token_type, scope = nil)
          @access_token = access_token
          @expires_in = expires_in
          @token_type = token_type
          @scope = scope
        end

        def current?
          return true if expiration_time.nil?

          Time.zone.now < expiration_time
        end

        def token_header
          return unless current?

          [token_type, access_token].join ' '
        end
      end
    end

    module Server
      class OauthProvider
        include Comparable

        attr_reader :name, :prefix
        attr_reader :token_url, :jwks_url, :user_info_url, :authorize_url
        attr_reader :issuer, :audience

        def initialize(name, prefix = nil)
          @name = name.to_s.downcase
          @prefix = prefix.to_s.downcase

          @token_url = get_env :token_url
          @jwks_url = get_env :jwks_url
          @user_info_url = get_env :user_info_url
          @authorize_url = get_env :authorize_url

          @issuer = get_env :jwt_issuer
          @audience = get_env :jwt_audience
        end

        def matches?(other_name)
          name == other_name.to_s.downcase
        end

        def <=>(other)
          to_s <=> other.to_s
        end

        def inspect
          format '#<%s name=%s>', self.class.name, name
        end

        alias to_s inspect

        private

        def get_env(key)
          Env.get build_full_key(key)
        end

        def build_full_key(key)
          ['oauth2', prefix.blank? ? nil : prefix, key].compact.map(&:to_s).join('_')
        end
      end

      class AuthToken
        def initialize(payload, header)
          @payload = SimpleHash.new payload
          @header = SimpleHash.new header
        end

        def to_a
          [payload.to_h, header.to_h]
        end

        def to_json(*args)
          to_a.to_json(*args)
        end
      end

      module_function

      def providers
        @providers ||= []
      end

      def add_provider(name, key)
        return false if provider?(name)

        providers << OauthProvider.new(name, key)
      end

      def add_providers_from_env(key = :oauth_providers)
        Env.get_list!(key).each { |x| add_provider x, x }
      end

      def get_provider(name)
        providers.find { |x| x.matches? name }
      end

      def provider?(name)
        providers.any? { |x| x.matches? name }
      end

      def validate_token(token)
        error = nil
        providers.each do |provider|
          auth_token, error = validate_token_with_provider token, provider
          return auth_token if auth_token.present?
        end
        raise error if error.present?
      end

      # @param [OauthProvider] provider
      def validate_token_with_provider(token, provider)
        options = {
          algorithm: 'RS256',
          iss: provider.issuer,
          verify_iss: true,
          aud: provider.audience,
          verify_aud: true
        }
        auth_token_ary = JWT.decode(token, nil, true, options) do |header|
          key_set = get_keys(provider)
          key_set[header['kid']]
        end
        auth_token = AuthToken.new(*auth_token_ary)
        [auth_token, nil]
      rescue JWT::DecodeError => e
        [nil, e]
      end

      def get_keys(provider)
        remote_key = "oauth2:keys:#{provider.name}"
        json = shared_cache.fetch(remote_key) { fetch_remote_key_set provider }
        json_crc = Zlib.crc32 json, nil
        local_key = "#{remote_key}:#{json_crc}"
        local_cache.fetch(local_key) do
          keys = Array(JSON.parse(json)['keys'])
          Hash[
            keys.map do |k|
              [k['kid'], OpenSSL::X509::Certificate.new(Base64.decode64(k['x5c'].first)).public_key]
            end
          ]
        end
      end

      def fetch_remote_key_set(provider)
        response = request :get, provider.jwks_url
        return response.body if response.status == 200

        raise StandardError, 'Failed to load authorization key set for tenant domain.'
      end

      def request(*args)
        JsonWebToken.request(*args)
      end

      def local_cache
        JsonWebToken.local_cache
      end

      def shared_cache
        JsonWebToken.shared_cache
      end

      def clear_cache
        JsonWebToken.clear_cache
      end
    end

    module_function

    def default_request_options
      @default_request_options ||= {}
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
      local_cache.clear
      shared_cache.clear
    end

    def ttl
      60.minutes
    end
  end
end
