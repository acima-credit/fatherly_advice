# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::JsonWebToken, :env_change do
  let(:key_set) do
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
  let(:http_token) do
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJUZzJNVGMyUVRVd01URXlSVFF3T1RJNE9UWXpNamsyUlVZME5qTkZPVUZCUWpaQ'\
      '1JUSkdNdyJ9.eyJpc3MiOiJodHRwczovL2FjaW1hY3JlZGl0LWRldi5hdXRoMC5jb20vIiwic3ViIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpV'\
      'mFWOERueDZKaWdAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vYmFuay1hY2NvdW50LmFjaW1hY3JlZGl0LmNvbS8iLCJpYXQiOjE1NjA1NDAyOTY'\
      'sImV4cCI6MTU2MDYyNjY5NiwiYXpwIjoiRXNzeUhwVkpOcDhVY0NwQnNteUdpVmFWOERueDZKaWciLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbH'\
      'MifQ.JRVz9K3wotmAmfgnLMq7oYvdMYEtCUgVmyPooFPAVvnQ_omuvOXYTjakArbVpl8YnPyuHfVkSgtdAis3G9xMB5PJbRG6PlC14mblahfWtR'\
      'ruTgmFZ8MRXkJRKF2FYKAyTEjDeqKuf0F0yfjQM2OPOrJ_t9f0btf3hJPHlgrkRywKg66DrfNV4sAx-G-JhRLwdrWwvz5oaBb-oj30Tyx7NuB'\
      '4R98mVZwMUvgYWSzEmNUqebbJDqt4eCWOUT9q_2nhPNbVfanD5hkGIg6gwaVpanGbA3997F6M_gQRho0R1-OWHH0qtatFxOYK4spVYo3Z6cC'\
      'kqQ0NOMtzY4T0S93CKg'
  end
  let(:token_generation_time) { Time.new(2019, 6, 14).in_time_zone }
  let(:keys_response) { Excon::Response.new body: key_set, status: 200 }
  context 'with basic env vars' do
    let(:env) do
      {
        'OAUTH2_DOMAIN' => 'acimacredit-dev.auth0.com',
        'OAUTH2_JWT_AUDIENCE' => 'https://bank-account.acimacredit.com/',
        'OAUTH2_ISSUER' => 'https://acimacredit-dev.auth0.com/'
      }
    end
    context 'validate_token' do
      let(:result) { described_class.validate_token http_token }
      it 'validates token from auth0' do
        described_class.cache.clear
        allow(Excon).to receive(:get).with(described_class.oauth2_jwks_url).and_return(keys_response)

        Timecop.travel(token_generation_time) do
          expect { result }.to_not raise_error
          expect(result.present?).to be_truthy
        end
      end
    end
    context 'validate_token' do
      let(:result) { described_class.validate_token http_token }
      it 'validates token from auth0' do
        described_class.cache.clear
        allow(Excon).to receive(:get).with(described_class.oauth2_jwks_url).and_return(keys_response)

        Timecop.travel(token_generation_time) do
          expect { result }.to_not raise_error
          expect(result.present?).to be_truthy
        end
      end
    end
    context 'env vars' do
      it('oauth2_domain') do
        expect(described_class.oauth2_domain).to eq 'acimacredit-dev.auth0.com'
      end
      it('oauth2_token_url') do
        expect(described_class.oauth2_token_url).to eq 'https://acimacredit-dev.auth0.com/oauth/token'
      end
      it('oauth2_jwks_url') do
        expect(described_class.oauth2_jwks_url).to eq 'https://acimacredit-dev.auth0.com/.well-known/jwks.json'
      end
      it('oauth2_full_issuer') do
        expect(described_class.oauth2_full_issuer).to eq 'https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer') do
        expect(described_class.oauth2_issuer).to eq 'https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer_list') do
        expect(described_class.oauth2_issuer_list).to be_nil
      end
      it('oauth2_jwt_audience') do
        expect(described_class.oauth2_jwt_audience).to eq 'https://bank-account.acimacredit.com/'
      end
    end
  end
  context 'with most env vars' do
    let(:env) do
      {
        'OAUTH2_DOMAIN' => 'acimacredit.auth0.com',
        'OAUTH2_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_JWKS_URL' => 'https://auth.acimacredit.com/api/.well-known/jwks.json',
        'OAUTH2_ISSUER' => 'https://acimacredit-dev.auth0.com/',
        'OAUTH2_JWT_AUDIENCE' => 'https://bank-account.acimacredit.com'
      }
    end
    context 'env vars' do
      it('oauth2_domain') do
        expect(described_class.oauth2_domain).to eq 'acimacredit.auth0.com'
      end
      it('oauth2_token_url') do
        expect(described_class.oauth2_token_url).to eq 'https://auth.acimacredit.com/api/oauth/token'
      end
      it('oauth2_jwks_url') do
        expect(described_class.oauth2_jwks_url).to eq 'https://auth.acimacredit.com/api/.well-known/jwks.json'
      end
      it('oauth2_full_issuer') do
        expect(described_class.oauth2_full_issuer).to eq 'https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer') do
        expect(described_class.oauth2_issuer).to eq 'https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer_list') do
        expect(described_class.oauth2_issuer_list).to be_nil
      end
      it('oauth2_jwt_audience') do
        expect(described_class.oauth2_jwt_audience).to eq 'https://bank-account.acimacredit.com'
      end
    end
  end
  context 'with all env vars' do
    let(:env) do
      {
        'OAUTH2_DOMAIN' => 'acimacredit.auth0.com',
        'OAUTH2_TOKEN_URL' => 'https://auth.acimacredit.com/api/oauth/token',
        'OAUTH2_JWKS_URL' => 'https://auth.acimacredit.com/api/.well-known/jwks.json',
        'OAUTH2_ISSUER' => 'https://acimacredit-dev.auth0.com/',
        'OAUTH2_ISSUER_LIST' => 'https://acimacredit.okta.com,https://acimacredit-dev.auth0.com/',
        'OAUTH2_JWT_AUDIENCE' => 'https://bank-account.acimacredit.com'
      }
    end
    context 'validate_token' do
      let(:result) { described_class.validate_token http_token }
      it 'validates token from auth0' do
        described_class.cache.clear
        allow(Excon).to receive(:get).with(described_class.oauth2_jwks_url).and_return(keys_response)

        Timecop.travel(token_generation_time) do
          expect { result }.to_not raise_error
          expect(result.present?).to be_truthy
        end
      end
    end
    context 'env vars' do
      it('oauth2_domain') do
        expect(described_class.oauth2_domain).to eq 'acimacredit.auth0.com'
      end
      it('oauth2_token_url') do
        expect(described_class.oauth2_token_url).to eq 'https://auth.acimacredit.com/api/oauth/token'
      end
      it('oauth2_jwks_url') do
        expect(described_class.oauth2_jwks_url).to eq 'https://auth.acimacredit.com/api/.well-known/jwks.json'
      end
      it('oauth2_full_issuer') do
        expect(described_class.oauth2_full_issuer).to eq 'https://acimacredit.okta.com or https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer') do
        expect(described_class.oauth2_issuer).to eq 'https://acimacredit-dev.auth0.com/'
      end
      it('oauth2_issuer_list') do
        expect(described_class.oauth2_issuer_list).to eq ['https://acimacredit.okta.com', 'https://acimacredit-dev.auth0.com/']
      end
      it('oauth2_jwt_audience') do
        expect(described_class.oauth2_jwt_audience).to eq 'https://bank-account.acimacredit.com'
      end
    end
  end
end
