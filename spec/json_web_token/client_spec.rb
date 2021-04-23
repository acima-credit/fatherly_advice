# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::JsonWebToken::Client, :env_change do
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

                Timecop.travel(auth0_token_generation_time) do
                  # first try - from source
                  Excon.stub({}, status: 200, body: auth0_token_body)
                  expect(Excon).to receive(:post).and_call_original
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
                  # second try - from cache
                  Excon.stubs.clear
                  expect(Excon).to_not receive(:post)
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

                Timecop.travel(auth0_token_generation_time) do
                  # first try - from source
                  Excon.stub({}, status: 200, body: auth0_token_body)
                  expect(Excon).to receive(:post).and_call_original
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
                  # second try - from cache
                  Excon.stubs.clear
                  expect(Excon).to_not receive(:post)
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
