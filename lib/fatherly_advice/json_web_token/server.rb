# frozen_string_literal: true

module FatherlyAdvice
  module JsonWebToken
    class Server
      class OauthProvider
        include EntryMixin
        include Comparable

        attr_reader :name, :prefix

        def initialize(name, prefix = nil)
          @name = name.to_s.downcase
          @prefix = prefix.to_s.downcase
        end

        def token_url
          get_env :token_url
        end

        def jwks_url
          get_env :jwks_url
        end

        def user_info_url
          get_env :user_info_url
        end

        def authorize_url
          get_env :authorize_url
        end

        def issuer
          get_env :jwt_issuer
        end

        def audience
          get_env :jwt_audience
        end

        def client_id
          get_env :m2m_client_id
        end

        def client_secret
          get_env :m2m_client_secret
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
