# frozen_string_literal: true

module FatherlyAdvice
  module JsonWebToken
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

        # @param [String] name the app we are a client of
        # @param [String] prefix the oauth provider prefix
        def initialize(name, prefix = nil)
          @name = name.to_s.downcase
          @prefix = prefix.to_s.downcase
        end

        def audience
          get_env format('%s_audience', name)
        end

        def grant_type
          get_env :grant_type, 'client_credentials'
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

        # Checks if we have all the required values to get an access token
        #
        # @param [String] app_name the name of the app we need to authenticate to
        def can_get_access_tokens?(app_name)
          providers = Server.providers.select { |x| x.token_url.present? }
          return false if providers.empty?

          app = get_app app_name
          providers.
            map { |provider| request_hash_for_access_token app, provider }.
            any? { |hsh| hsh.values.all?(&:present?) }
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
          request_hash = request_hash_for_access_token app, provider
          missing_keys = request_hash.select { |_k, v| v.nil? }.keys
          raise ArgumentError, "missing #{missing_keys.first}" if missing_keys.present?

          response = request :post, provider.token_url, body: request_hash.to_json
          return nil unless response.status >= 200 && response.status < 300

          AccessToken.from_json(response.body).tap(&:reset_expiration_time)
        end

        # build a request hash body for an access token
        #
        # @param [App] app the app we are trying to reach
        # @param [Server::Provider] provider the oauth2 provider we will use to authenticate
        def request_hash_for_access_token(app, provider)
          {
            client_id: provider.client_id,
            client_secret: provider.client_secret,
            audience: app.audience,
            grant_type: app.grant_type
          }
        end
      end
    end
  end
end
