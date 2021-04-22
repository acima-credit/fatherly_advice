# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::JsonWebToken::Client, :env_change, :focus2 do
  let(:server_class) { FatherlyAdvice::JsonWebToken::Server }
  after do
    server_class.providers.clear
    described_class.apps.clear
  end
  context 'with non-prefixed env vars' do
    before do
      server_class.add_provider 'auth0', nil
      described_class.add_app 'bank_account', nil
    end
    let(:env) do
      {
        'OAUTH2_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_M2M_CLIENT_ID' => 'EssyHpVJNp8UcCpBsmyGiVaV8Dnx6Jig',
        'OAUTH2_M2M_CLIENT_SECRET' => '_90JfHhJWDlwmW7St9B0RmE0OFW5dfm8YgrjnkDddCNt7SUf4zskIF-SUXk2UsLv',
        'OAUTH2_BANK_ACCOUNT_AUDIENCE' => 'https://bank-account.acimacredit.com'
      }
    end
    context 'apps' do
      let(:app_names) { described_class.apps.map(&:name) }
      it('app names') { expect(app_names).to eq ['bank_account'] }
      let(:app) { described_class.get_app name }
      context 'bank_account' do
        let(:name) { 'bank_account' }
        let(:auth0_access_token) do
          'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJUZzJNVGMyUVRVd01URXlSVFF3T1RJNE9UWXpNamsyUlVZME5qTkZPVUZCUWpaQ1JUSkdNdyJ9.eyJodHRwczovL2Fja' \
            'W1hY3JlZGl0LmNvbS9jYW5vbmljYWxfbmFtZSI6ImJhbmstYWNjb3VudCIsImh0dHBzOi8vYWNpbWFjcmVkaXQuY29tL2ludGVybmFsX2NsaWVudCI6ZmFsc2UsImlzcyI6Imh0d' \
            'HBzOi8vYWNpbWFjcmVkaXQtZGV2LmF1dGgwLmNvbS8iLCJzdWIiOiJFc3N5SHBWSk5wOFVjQ3BCc215R2lWYVY4RG54NkppZ0BjbGllbnRzIiwiYXVkIjoiaHR0cHM6Ly9iYW5rL' \
            'WFjY291bnQuYWNpbWFjcmVkaXQuY29tIiwiaWF0IjoxNjE5MTE1NjUzLCJleHAiOjE2MTkxNTE2NTMsImF6cCI6IkVzc3lIcFZKTnA4VWNDcEJzbXlHaVZhVjhEbng2SmlnIiwiZ' \
            '3R5IjoiY2xpZW50LWNyZWRlbnRpYWxzIn0.VTdXym9Y6zjqx04iZ9-pI8LQwd61c_Ha3W-SVe_NY1ardSFG2WGlG_Mix0OWPYl6MPB8mzepDvYiziv-ElHhxY1wvEv-NpLgyytAV' \
            '5QY6YC0wALtrPxNtsDRKqVkpPkUQDvIwxBXOLajnV8juTOdtPXmNytKFcbnA-zpdc3eyb94px5ItbKyNwzakSdseVzyFh17Kf66d4kscZKG0LtyqV2Z9gUDa-W6EsLBl9x2vsqYc' \
            'YW5L9Ddg4ZolstqHFBpLWXFDbSoxBskZzpoOuqGFMXGdv0-oSa2-5vcfVsx8lKiXrhSHzRN-BPg5gpnIYGDJl7FAgzaTr48akpjh-fIKw'
        end
        let(:auth0_token_body) { %({ "access_token": "#{auth0_access_token}", "expires_in": 36000, "token_type": "Bearer" }) }
        let(:auth0_token_generation_time) { Time.new(2021, 4, 22).in_time_zone }
        context 'instance' do
          it('name') { expect(app.name).to eq name }
          it('prefix') { expect(app.prefix).to eq '' }
          it('audience') { expect(app.audience).to eq 'https://bank-account.acimacredit.com' }
          it('grant_type') { expect(app.grant_type).to eq 'client_credentials' }
        end
        context 'provider' do
          let(:provider) { server_class.get_provider 'auth0' }
          it('name') { expect(provider.name).to eq 'auth0' }
          it('prefix') { expect(provider.prefix).to eq '' }
          it('token_url') { expect(provider.token_url).to eq 'https://auth.acimacredit.com/api/oauth/token' }
          it('jwks_url') { expect(provider.jwks_url).to be_nil }
          it('user_info_url') { expect(provider.user_info_url).to be_nil }
          it('authorize_url') { expect(provider.authorize_url).to be_nil }
          it('issuer') { expect(provider.issuer).to be_nil }
          it('audience') { expect(provider.audience).to be_nil }
          it('client_id') { expect(provider.client_id).to eq 'EssyHpVJNp8UcCpBsmyGiVaV8Dnx6Jig' }
          it('client_secret') { expect(provider.client_secret).to eq '_90JfHhJWDlwmW7St9B0RmE0OFW5dfm8YgrjnkDddCNt7SUf4zskIF-SUXk2UsLv' }
        end
        context 'client' do
          context 'get_access_tokens' do
            let(:result) { described_class.get_access_tokens name }
            context 'with success' do
              it 'gets a one-item list of tokens' do
                described_class.clear_cache
                Excon.stub({}, status: 200, body: auth0_token_body)

                Timecop.travel(auth0_token_generation_time) do
                  expect { result }.to_not raise_error
                  expect(result).to be_a Array
                  expect(result.size).to eq 1
                  token = result.first
                  expect(token).to be_a described_class::AccessToken
                  expect(token.access_token).to eq auth0_access_token
                  expect(token.expires_in).to eq 36_000
                  expect(token.token_type).to eq 'Bearer'
                  expect(token.scope).to be_nil
                  expect(token.expiration_time.to_s).to eq '2021-04-22 10:00:00 -0600'
                end
              end
            end
            context 'with failure' do
              context 'on unauthorized' do
                it 'returns an empty array' do
                  described_class.clear_cache
                  Excon.stub({}, status: 401, body: '')

                  expect { result }.to_not raise_error
                  expect(result).to be_a Array
                  expect(result).to be_empty
                end
              end
            end
          end
        end
      end
    end
  end
  context 'with prefixed env vars' do
    before do
      server_class.add_provider 'auth0', 'auth0'
      described_class.add_apps_from_env
    end
    let(:env) do
      {
        'OAUTH_APPS' => 'bank_account',
        'OAUTH2_AUTH0_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_AUTH0_M2M_CLIENT_ID' => 'EssyHpVJNp8UcCpBsmyGiVaV8Dnx6Jig',
        'OAUTH2_AUTH0_M2M_CLIENT_SECRET' => '_90JfHhJWDlwmW7St9B0RmE0OFW5dfm8YgrjnkDddCNt7SUf4zskIF-SUXk2UsLv',
        'OAUTH2_AUTH0_BANK_ACCOUNT_AUDIENCE' => 'https://bank-account.acimacredit.com'
      }
    end
    context 'apps' do
      let(:app_names) { described_class.apps.map(&:name) }
      it('app names') { expect(app_names).to eq ['bank_account'] }
      let(:app) { described_class.get_app name }
      context 'bank_account', :focus2 do
        let(:name) { 'bank_account' }
        let(:auth0_access_token) do
          'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJUZzJNVGMyUVRVd01URXlSVFF3T1RJNE9UWXpNamsyUlVZME5qTkZPVUZCUWpaQ1JUSkdNdyJ9.eyJodHRwczovL2Fja' \
            'W1hY3JlZGl0LmNvbS9jYW5vbmljYWxfbmFtZSI6ImJhbmstYWNjb3VudCIsImh0dHBzOi8vYWNpbWFjcmVkaXQuY29tL2ludGVybmFsX2NsaWVudCI6ZmFsc2UsImlzcyI6Imh0d' \
            'HBzOi8vYWNpbWFjcmVkaXQtZGV2LmF1dGgwLmNvbS8iLCJzdWIiOiJFc3N5SHBWSk5wOFVjQ3BCc215R2lWYVY4RG54NkppZ0BjbGllbnRzIiwiYXVkIjoiaHR0cHM6Ly9iYW5rL' \
            'WFjY291bnQuYWNpbWFjcmVkaXQuY29tIiwiaWF0IjoxNjE5MTE1NjUzLCJleHAiOjE2MTkxNTE2NTMsImF6cCI6IkVzc3lIcFZKTnA4VWNDcEJzbXlHaVZhVjhEbng2SmlnIiwiZ' \
            '3R5IjoiY2xpZW50LWNyZWRlbnRpYWxzIn0.VTdXym9Y6zjqx04iZ9-pI8LQwd61c_Ha3W-SVe_NY1ardSFG2WGlG_Mix0OWPYl6MPB8mzepDvYiziv-ElHhxY1wvEv-NpLgyytAV' \
            '5QY6YC0wALtrPxNtsDRKqVkpPkUQDvIwxBXOLajnV8juTOdtPXmNytKFcbnA-zpdc3eyb94px5ItbKyNwzakSdseVzyFh17Kf66d4kscZKG0LtyqV2Z9gUDa-W6EsLBl9x2vsqYc' \
            'YW5L9Ddg4ZolstqHFBpLWXFDbSoxBskZzpoOuqGFMXGdv0-oSa2-5vcfVsx8lKiXrhSHzRN-BPg5gpnIYGDJl7FAgzaTr48akpjh-fIKw'
        end
        let(:auth0_token_body) { %({ "access_token": "#{auth0_access_token}", "expires_in": 36000, "token_type": "Bearer" }) }
        let(:auth0_token_generation_time) { Time.new(2021, 4, 22).in_time_zone }
        context 'instance' do
          it('name') { expect(app.name).to eq name }
          it('prefix') { expect(app.prefix).to eq 'auth0' }
          it('audience') { expect(app.audience).to eq 'https://bank-account.acimacredit.com' }
          it('grant_type') { expect(app.grant_type).to eq 'client_credentials' }
        end
        context 'provider' do
          let(:provider) { server_class.get_provider 'auth0' }
          it('name') { expect(provider.name).to eq 'auth0' }
          it('prefix') { expect(provider.prefix).to eq 'auth0' }
          it('token_url') { expect(provider.token_url).to eq 'https://auth.acimacredit.com/api/oauth/token' }
          it('jwks_url') { expect(provider.jwks_url).to be_nil }
          it('user_info_url') { expect(provider.user_info_url).to be_nil }
          it('authorize_url') { expect(provider.authorize_url).to be_nil }
          it('issuer') { expect(provider.issuer).to be_nil }
          it('audience') { expect(provider.audience).to be_nil }
          it('client_id') { expect(provider.client_id).to eq 'EssyHpVJNp8UcCpBsmyGiVaV8Dnx6Jig' }
          it('client_secret') { expect(provider.client_secret).to eq '_90JfHhJWDlwmW7St9B0RmE0OFW5dfm8YgrjnkDddCNt7SUf4zskIF-SUXk2UsLv' }
        end
        context 'client' do
          context 'get_access_tokens' do
            let(:result) { described_class.get_access_tokens name }
            context 'with success' do
              it 'gets a one-item list of tokens' do
                described_class.clear_cache
                Excon.stub({}, status: 200, body: auth0_token_body)

                Timecop.travel(auth0_token_generation_time) do
                  expect { result }.to_not raise_error
                  expect(result).to be_a Array
                  expect(result.size).to eq 1
                  token = result.first
                  expect(token).to be_a described_class::AccessToken
                  expect(token.access_token).to eq auth0_access_token
                  expect(token.expires_in).to eq 36_000
                  expect(token.token_type).to eq 'Bearer'
                  expect(token.scope).to be_nil
                  expect(token.expiration_time.to_s).to eq '2021-04-22 10:00:00 -0600'
                end
              end
            end
            context 'with failure' do
              context 'on unauthorized' do
                it 'returns an empty array' do
                  described_class.clear_cache
                  Excon.stub({}, status: 401, body: '')

                  expect { result }.to_not raise_error
                  expect(result).to be_a Array
                  expect(result).to be_empty
                end
              end
            end
          end
        end
      end
    end
  end
end

RSpec.describe FatherlyAdvice::JsonWebToken::Server, :env_change do
  after { described_class.providers.clear }
  context 'with non-prefixed env vars' do
    before { described_class.add_provider 'auth0', nil }
    let(:env) do
      {
        'OAUTH2_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_JWKS_URL' => 'https://auth.acimacredit.com/api/.well-known/jwks.json',
        'OAUTH2_USER_INFO_URL' => 'https://auth.acimacredit.com/api/userinfo',
        'OAUTH2_AUTHORIZE_URL' => 'https://auth.acimacredit.com/api/authorize',
        'OAUTH2_JWT_ISSUER' => 'https://acimacredit-dev.auth0.com/',
        'OAUTH2_JWT_AUDIENCE' => 'https://bank-account.acimacredit.com/'
      }
    end
    context 'providers' do
      let(:provider_names) { described_class.providers.map(&:name) }
      it('provider names') { expect(provider_names).to eq ['auth0'] }
      let(:provider) { described_class.get_provider name }
      context 'auth0' do
        let(:name) { 'auth0' }
        let(:auth0_key_set) do
          <<~JSON
            {
              "keys": [
                {
                  "alg": "RS256",
                  "kty": "RSA",
                  "use": "sig",
                  "x5c": [
                    "MIIDDTCCAfWgAwIBAgIJVkvyxSlkznG2MA0GCSqGSIb3DQEBCwUAMCQxIjAgBgNVBAMTGWFjaW1hY3JlZGl0LWRldi5hdXRoMC5jb20wHhcNMTkwNTA2MjA1MzI4WhcNMzMwMTEyMjA1MzI4WjAkMSIwIAYDVQQDExlhY2ltYWNyZWRpdC1kZXYuYXV0aDAuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtqnhrDDqFtS4Nam/FLxZTreEtsOvGPReaVfHEty9TV6W2Q/SJSVuBu2QgCNg4TdHqyLwvVjXch41Ym5HoguN4ClT414GO6f/7c9Q1b4joxhiG3mEQJorGTezMBYZ2ffIiRlDPsPdzfRzw3oJvSwJIkhREU9ItV9V1B9gIoGq6bQBBweeJ9fnkrCkeN8wcJ3p5JfqbPfFbLDWwSBgvByguNzApBUKhf3j10MbVQXh5I/cXDON0/ncTkzV958VALUrs22AAhR6WyLSo4u6dyPnzeqMBtSPeEIal7Q9d9Rw3xOFMma0cBVV9i+e8BGTGDqYkb62lAvL+9Yj8vFAfHC6qwIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRX4uhmbgJiotuIRyDqJpkeNLVVQjAOBgNVHQ8BAf8EBAMCAoQwDQYJKoZIhvcNAQELBQADggEBAJeJ6qcJk8x0Do1DgofbUaalSDrCI/M/U4zgYjGfoIvsFVu2fo+owy99L6lTPJlagUTMYLm8idg0I3vYA1WgGUS5YXzJ1Ek1qnKBsqMS+dnx2mkPUyNv4i60iv5hsjXMY0wlGem5DKQHWqbNk3jJ0LaVF0pPlpHsMIS2XU5dffDJGJ44gyVxu/00M+0H8ZjiMneyTPoFUHZThrbygfhifNdMFxtjyMm3I/8jZMQZr/Rg6aafFfDk9WWKMO73GfQ4tdNmrem/Vfxv1dWIhZIaKJH9/ENG0VYgR/SpSRhwdSL/rU8cddxy/dXbS4CT8hoq2bDM/LKeGcBzHjjqaH4mZ5M="
                  ],
                  "n": "tqnhrDDqFtS4Nam_FLxZTreEtsOvGPReaVfHEty9TV6W2Q_SJSVuBu2QgCNg4TdHqyLwvVjXch41Ym5HoguN4ClT414GO6f_7c9Q1b4joxhiG3mEQJorGTezMBYZ2ffIiRlDPsPdzfRzw3oJvSwJIkhREU9ItV9V1B9gIoGq6bQBBweeJ9fnkrCkeN8wcJ3p5JfqbPfFbLDWwSBgvByguNzApBUKhf3j10MbVQXh5I_cXDON0_ncTkzV958VALUrs22AAhR6WyLSo4u6dyPnzeqMBtSPeEIal7Q9d9Rw3xOFMma0cBVV9i-e8BGTGDqYkb62lAvL-9Yj8vFAfHC6qw",
                  "e": "AQAB",
                  "kid": "RTg2MTc2QTUwMTEyRTQwOTI4OTYzMjk2RUY0NjNFOUFBQjZCRTJGMw",
                  "x5t": "RTg2MTc2QTUwMTEyRTQwOTI4OTYzMjk2RUY0NjNFOUFBQjZCRTJGMw"
                }
              ]
            }
          JSON
        end
        let(:auth0_keys_response) { Excon::Response.new body: auth0_key_set, status: 200 }
        let(:auth0_http_token) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJUZzJNVGMyUVRVd01URXlSVFF3T1RJNE9UWXpNamsyUlVZME5qTkZPVUZCUWpaQ'\
          '1JUSkdNdyJ9.eyJpc3MiOiJodHRwczovL2FjaW1hY3JlZGl0LWRldi5hdXRoMC5jb20vIiwic3ViIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpV'\
          'mFWOERueDZKaWdAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vYmFuay1hY2NvdW50LmFjaW1hY3JlZGl0LmNvbS8iLCJpYXQiOjE1NjA1NDAyOTY'\
          'sImV4cCI6MTU2MDYyNjY5NiwiYXpwIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpVmFWOERueDZKaWciLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbH'\
          'MifQ.JRVz9K3wotmAmfgnLMq7oYvdMYEtCUgVmyPooFPAVvnQ_omuvOXYTjakArbVpl8YnPyuHfVkSgtdAis3G9xMB5PJbRG6PlC14mblahfWtR'\
          'ruTgmFZ8MRXkJRKF2FYKAyTEjDeqKuf0F0yfjQM2OPOrJ_t9f0btf3hJPHlgrkRywKg66DrfNV4sAx-G-JhRLwdrWwvz5oaBb-oj30Tyx7NuB'\
          '4R98mVZwMUvgYWSzEmNUqebbJDqt4eCWOUT9q_2nhPNbVfanD5hkGIg6gwaVpanGbA3997F6M_gQRho0R1-OWHH0qtatFxOYK4spVYo3Z6cC'\
          'kqQ0NOMtzY4T0S93CKg'
        end
        let(:auth0_token_generation_time) { Time.new(2019, 6, 14).in_time_zone }
        context 'instance' do
          it('name') { expect(provider.name).to eq name }
          it('prefix') { expect(provider.prefix).to eq '' }
          it('token_url') { expect(provider.token_url).to eq 'https://auth.acimacredit.com/api/oauth/token' }
          it('jwks_url') { expect(provider.jwks_url).to eq 'https://auth.acimacredit.com/api/.well-known/jwks.json' }
          it('user_info_url') { expect(provider.user_info_url).to eq 'https://auth.acimacredit.com/api/userinfo' }
          it('authorize_url') { expect(provider.authorize_url).to eq 'https://auth.acimacredit.com/api/authorize' }
          it('issuer') { expect(provider.issuer).to eq 'https://acimacredit-dev.auth0.com/' }
          it('audience') { expect(provider.audience).to eq 'https://bank-account.acimacredit.com/' }
          it('client_id') { expect(provider.client_id).to be_nil }
          it('client_secret') { expect(provider.client_secret).to be_nil }
        end
        context 'server' do
          context 'validate_token' do
            let(:result) { described_class.validate_token auth0_http_token }
            context 'with success' do
              it 'validates token' do
                described_class.clear_cache
                Excon.stub({}, status: 200, body: auth0_key_set)

                Timecop.travel(auth0_token_generation_time) do
                  expect { result }.to_not raise_error
                  expect(result.present?).to be_truthy
                  expect(result).to be_a described_class::AuthToken
                end
              end
            end
            context 'with failure' do
              context 'on expired credentials' do
                it 'validates token from auth0' do
                  described_class.clear_cache
                  Excon.stub({}, status: 200, body: auth0_key_set)

                  expect { result }.to raise_error JWT::ExpiredSignature, 'Signature has expired'
                end
              end
            end
          end
        end
      end
    end
  end
  context 'with prefixed env vars' do
    before { described_class.add_providers_from_env }
    let(:env) do
      {
        'OAUTH_PROVIDERS' => 'auth0',
        'OAUTH2_AUTH0_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_AUTH0_JWKS_URL' => 'https://auth.acimacredit.com/api/.well-known/jwks.json',
        'OAUTH2_AUTH0_USER_INFO_URL' => 'https://auth.acimacredit.com/api/userinfo',
        'OAUTH2_AUTH0_AUTHORIZE_URL' => 'https://auth.acimacredit.com/api/authorize',
        'OAUTH2_AUTH0_JWT_ISSUER' => 'https://acimacredit-dev.auth0.com/',
        'OAUTH2_AUTH0_JWT_AUDIENCE' => 'https://bank-account.acimacredit.com/'
      }
    end
    context 'providers' do
      let(:provider_names) { described_class.providers.map(&:name) }
      it('provider names') { expect(provider_names).to eq ['auth0'] }
      let(:provider) { described_class.get_provider name }
      context 'auth0' do
        let(:name) { 'auth0' }
        let(:auth0_key_set) do
          <<~JSON
            {
              "keys": [
                {
                  "alg": "RS256",
                  "kty": "RSA",
                  "use": "sig",
                  "x5c": [
                    "MIIDDTCCAfWgAwIBAgIJVkvyxSlkznG2MA0GCSqGSIb3DQEBCwUAMCQxIjAgBgNVBAMTGWFjaW1hY3JlZGl0LWRldi5hdXRoMC5jb20wHhcNMTkwNTA2MjA1MzI4WhcNMzMwMTEyMjA1MzI4WjAkMSIwIAYDVQQDExlhY2ltYWNyZWRpdC1kZXYuYXV0aDAuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtqnhrDDqFtS4Nam/FLxZTreEtsOvGPReaVfHEty9TV6W2Q/SJSVuBu2QgCNg4TdHqyLwvVjXch41Ym5HoguN4ClT414GO6f/7c9Q1b4joxhiG3mEQJorGTezMBYZ2ffIiRlDPsPdzfRzw3oJvSwJIkhREU9ItV9V1B9gIoGq6bQBBweeJ9fnkrCkeN8wcJ3p5JfqbPfFbLDWwSBgvByguNzApBUKhf3j10MbVQXh5I/cXDON0/ncTkzV958VALUrs22AAhR6WyLSo4u6dyPnzeqMBtSPeEIal7Q9d9Rw3xOFMma0cBVV9i+e8BGTGDqYkb62lAvL+9Yj8vFAfHC6qwIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRX4uhmbgJiotuIRyDqJpkeNLVVQjAOBgNVHQ8BAf8EBAMCAoQwDQYJKoZIhvcNAQELBQADggEBAJeJ6qcJk8x0Do1DgofbUaalSDrCI/M/U4zgYjGfoIvsFVu2fo+owy99L6lTPJlagUTMYLm8idg0I3vYA1WgGUS5YXzJ1Ek1qnKBsqMS+dnx2mkPUyNv4i60iv5hsjXMY0wlGem5DKQHWqbNk3jJ0LaVF0pPlpHsMIS2XU5dffDJGJ44gyVxu/00M+0H8ZjiMneyTPoFUHZThrbygfhifNdMFxtjyMm3I/8jZMQZr/Rg6aafFfDk9WWKMO73GfQ4tdNmrem/Vfxv1dWIhZIaKJH9/ENG0VYgR/SpSRhwdSL/rU8cddxy/dXbS4CT8hoq2bDM/LKeGcBzHjjqaH4mZ5M="
                  ],
                  "n": "tqnhrDDqFtS4Nam_FLxZTreEtsOvGPReaVfHEty9TV6W2Q_SJSVuBu2QgCNg4TdHqyLwvVjXch41Ym5HoguN4ClT414GO6f_7c9Q1b4joxhiG3mEQJorGTezMBYZ2ffIiRlDPsPdzfRzw3oJvSwJIkhREU9ItV9V1B9gIoGq6bQBBweeJ9fnkrCkeN8wcJ3p5JfqbPfFbLDWwSBgvByguNzApBUKhf3j10MbVQXh5I_cXDON0_ncTkzV958VALUrs22AAhR6WyLSo4u6dyPnzeqMBtSPeEIal7Q9d9Rw3xOFMma0cBVV9i-e8BGTGDqYkb62lAvL-9Yj8vFAfHC6qw",
                  "e": "AQAB",
                  "kid": "RTg2MTc2QTUwMTEyRTQwOTI4OTYzMjk2RUY0NjNFOUFBQjZCRTJGMw",
                  "x5t": "RTg2MTc2QTUwMTEyRTQwOTI4OTYzMjk2RUY0NjNFOUFBQjZCRTJGMw"
                }
              ]
            }
          JSON
        end
        let(:auth0_keys_response) { Excon::Response.new body: auth0_key_set, status: 200 }
        let(:auth0_http_token) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJUZzJNVGMyUVRVd01URXlSVFF3T1RJNE9UWXpNamsyUlVZME5qTkZPVUZCUWpaQ'\
          '1JUSkdNdyJ9.eyJpc3MiOiJodHRwczovL2FjaW1hY3JlZGl0LWRldi5hdXRoMC5jb20vIiwic3ViIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpV'\
          'mFWOERueDZKaWdAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vYmFuay1hY2NvdW50LmFjaW1hY3JlZGl0LmNvbS8iLCJpYXQiOjE1NjA1NDAyOTY'\
          'sImV4cCI6MTU2MDYyNjY5NiwiYXpwIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpVmFWOERueDZKaWciLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbH'\
          'MifQ.JRVz9K3wotmAmfgnLMq7oYvdMYEtCUgVmyPooFPAVvnQ_omuvOXYTjakArbVpl8YnPyuHfVkSgtdAis3G9xMB5PJbRG6PlC14mblahfWtR'\
          'ruTgmFZ8MRXkJRKF2FYKAyTEjDeqKuf0F0yfjQM2OPOrJ_t9f0btf3hJPHlgrkRywKg66DrfNV4sAx-G-JhRLwdrWwvz5oaBb-oj30Tyx7NuB'\
          '4R98mVZwMUvgYWSzEmNUqebbJDqt4eCWOUT9q_2nhPNbVfanD5hkGIg6gwaVpanGbA3997F6M_gQRho0R1-OWHH0qtatFxOYK4spVYo3Z6cC'\
          'kqQ0NOMtzY4T0S93CKg'
        end
        let(:auth0_token_generation_time) { Time.new(2019, 6, 14).in_time_zone }
        context 'instance' do
          it('name') { expect(provider.name).to eq name }
          it('prefix') { expect(provider.prefix).to eq 'auth0' }
          it('token_url') { expect(provider.token_url).to eq 'https://auth.acimacredit.com/api/oauth/token' }
          it('jwks_url') { expect(provider.jwks_url).to eq 'https://auth.acimacredit.com/api/.well-known/jwks.json' }
          it('user_info_url') { expect(provider.user_info_url).to eq 'https://auth.acimacredit.com/api/userinfo' }
          it('authorize_url') { expect(provider.authorize_url).to eq 'https://auth.acimacredit.com/api/authorize' }
          it('issuer') { expect(provider.issuer).to eq 'https://acimacredit-dev.auth0.com/' }
          it('audience') { expect(provider.audience).to eq 'https://bank-account.acimacredit.com/' }
          it('client_id') { expect(provider.client_id).to be_nil }
          it('client_secret') { expect(provider.client_secret).to be_nil }
        end
        context 'server' do
          context 'validate_token' do
            let(:result) { described_class.validate_token auth0_http_token }
            context 'with success' do
              it 'validates token' do
                described_class.clear_cache
                Excon.stub({}, status: 200, body: auth0_key_set)

                Timecop.travel(auth0_token_generation_time) do
                  expect { result }.to_not raise_error
                  expect(result.present?).to be_truthy
                  expect(result).to be_a described_class::AuthToken
                end
              end
            end
            context 'with failure' do
              context 'on expired credentials' do
                it 'validates token from auth0' do
                  described_class.clear_cache
                  Excon.stub({}, status: 200, body: auth0_key_set)

                  expect { result }.to raise_error JWT::ExpiredSignature, 'Signature has expired'
                end
              end
            end
            context 'with success and failure' do
              it 'validates token and fails later' do
                described_class.clear_cache

                Timecop.travel(auth0_token_generation_time) do
                  # success example
                  Excon.stub({}, status: 200, body: auth0_key_set)
                  expect { result }.to_not raise_error
                  expect(result).to be_a described_class::AuthToken
                  # failure example
                  expect(Excon).to_not receive(:get)
                  expect { described_class.validate_token 'not_valid_token' }.to raise_error JWT::DecodeError, 'Not enough or too many segments'
                end
              end
            end
          end
        end
      end
    end
  end
end
