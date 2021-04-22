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

    class Client
      class AccessToken
        def self.from_json(json)
          hsh = JSON.parse json, symbolize_names: true
          new hsh[:access_token], hsh[:expires_in], hsh[:token_type], hsh[:scope]
        end

        attr_reader :access_token, :expires_in, :token_type, :scope
        attr_accessor :expiration_time

        def initialize(access_token, expires_in, token_type, scope = nil)
          @access_token = access_token
          @expires_in = expires_in.to_i
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

        def reset_expiration_time
          @expiration_time = Time.zone.now + expires_in
        end
      end

      # Server:
      #   [X] OAUTH2_XYZ_TOKEN_URL
      # Client:
      #   [ ] OAUTH2_XYZ_M2M_CLIENT_ID
      #   [ ] OAUTH2_XYZ_M2M_CLIENT_SECRET
      # Apps:
      #   [ ] OAUTH2_XYZ_BANK_ACCOUNT_AUDIENCE

      class App
        include EntryMixin
        include Comparable

        attr_reader :name, :prefix
        attr_reader :audience, :grant_type

        # @param [String] name the app we are a client of
        # @param [String] prefix the oauth provider prefix
        def initialize(name, prefix = nil)
          @name = name.to_s.downcase
          @prefix = prefix.to_s.downcase

          @audience = get_env format('%s_audience', name)
          @grant_type = get_env :grant_type, 'client_credentials'
        end
      end

      class << self
        delegate :request, :local_cache, :shared_cache, :clear_cache, to: JsonWebToken

        def apps
          @apps ||= []
        end

        def add_app(name, key)
          return false if app?(name)

          apps << App.new(name, key)
        end

        def add_apps_from_env(key = :oauth_apps)
          Env.get_list!(key).each do |app_name|
            Server.providers.each do |provider|
              add_app app_name, provider.name
            end
          end
        end

        def get_app(name)
          apps.find { |x| x.matches? name }
        end

        def app?(name)
          apps.any? { |x| x.matches? name }
        end

        # Get access tokens from all known oauth2 providers for an app we are trying to reach
        #
        # @param [String] app_name the name of the app we need to authenticate to
        def get_access_tokens(app_name)
          app = get_app app_name
          Server.providers.map { |provider| get_access_token_for_provider app, provider }.compact
        end

        # Get an access token for an app from an oauth2 provider from cache
        #
        # @param [App] app the app we are trying to reach
        # @param [Server::Provider] provider the oauth2 provider we will use to authenticate
        def get_access_token_for_provider(app, provider)
          key = "oauth2:token:#{app.name}:#{provider.name}"
          shared_cache.fetch(key) { fetch_access_token app, provider }
        end

        # Fetch the access token from the oauth2 provider
        #
        # @param [App] app the app we are trying to reach
        # @param [Server::Provider] provider the oauth2 provider we will use to authenticate
        def fetch_access_token(app, provider)
          request_hash = {
            client_id: provider.client_id,
            client_secret: provider.client_secret,
            audience: app.audience,
            grant_type: app.grant_type
          }
          response = request :post, provider.token_url, body: request_hash.to_json
          return nil unless response.status >= 200 && response.status < 300

          AccessToken.from_json(response.body).tap(&:reset_expiration_time)
        end
      end
    end

    class Server
      class OauthProvider
        include EntryMixin
        include Comparable

        attr_reader :name, :prefix
        attr_reader :token_url, :jwks_url, :user_info_url, :authorize_url
        attr_reader :issuer, :audience
        attr_reader :client_id, :client_secret

        def initialize(name, prefix = nil)
          @name = name.to_s.downcase
          @prefix = prefix.to_s.downcase

          @token_url = get_env :token_url
          @jwks_url = get_env :jwks_url
          @user_info_url = get_env :user_info_url
          @authorize_url = get_env :authorize_url

          @issuer = get_env :jwt_issuer
          @audience = get_env :jwt_audience

          @client_id = get_env :m2m_client_id
          @client_secret = get_env :m2m_client_secret
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

      class << self
        delegate :request, :local_cache, :shared_cache, :clear_cache, to: JsonWebToken

        def providers
          @providers ||= []
        end

        def add_provider(name, prefix)
          return false if provider?(name)

          providers << OauthProvider.new(name, prefix)
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
      end
    end
  end
end
