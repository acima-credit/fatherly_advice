# frozen_string_literal: true

module FatherlyAdvice
  module JsonWebToken
    module_function

    def validate_token(token)
      puts ">> validate_token | iss : #{oauth2_full_issuer.inspect}"
      JWT.decode(token,
                 nil,
                 true,
                 algorithm: 'RS256',
                 iss: oauth2_full_issuer,
                 verify_iss: true,
                 aud: oauth2_jwt_audience,
                 verify_aud: true) do |header|
        key_set = get_keys
        key_set[header['kid']]
      end
    end

    def get_keys
      keys = Array(JSON.parse(cached_key_set)['keys'])
      Hash[
        keys.map do |k|
          [k['kid'], OpenSSL::X509::Certificate.new(Base64.decode64(k['x5c'].first)).public_key]
        end
      ]
    end

    def oauth2_domain
      Env.get :oauth2_domain
    end

    def oauth2_token_url
      Env.get :oauth2_token_url, "https://#{oauth2_domain}/oauth/token"
    end

    def oauth2_jwks_url
      Env.get :oauth2_jwks_url, "https://#{oauth2_domain}/.well-known/jwks.json"
    end

    def oauth2_full_issuer
      issuers = oauth2_issuer_list
      return oauth2_issuer if issuers.blank?

      issuers.join(' or ')
    end

    def oauth2_issuer
      Env.get :oauth2_issuer, "https://#{oauth2_domain}"
    end

    def oauth2_issuer_list
      return nil unless Env.key?(:oauth2_issuer_list)

      Env.get(:oauth2_issuer_list).split(',')
    end

    def oauth2_jwt_audience
      Env.get :oauth2_jwt_audience, 'missing'
    end

    def cached_key_set
      cache.fetch("oauth2:keys:#{oauth2_domain}") { fetch_remote_key_set }
    end

    def fetch_remote_key_set
      response = Excon.get oauth2_jwks_url
      return response.body if response.status == 200

      raise(StandardError, 'Failed to load authorization key set for tenant domain.')
    end

    def cache
      @cache ||= ActiveSupport::Cache::RedisCacheStore.new url: Env.get(:redis_url),
                                                           expires_in: 60.minutes,
                                                           namespace: 'jwt:cache'
    end
  end
end
