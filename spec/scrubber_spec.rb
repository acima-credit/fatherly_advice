# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::Scrubber do
  let(:keys) { %i[username password age] }
  subject { described_class.new(*keys) }

  let(:basic) { { username: 'user', 'password' => 'pw', age: 35 } }
  let(:basic_cnv) { { :age => '**', 'password' => '**', :username => '****' } }

  context 'basics' do
    it { expect(subject).to be_a described_class }
    let(:result) { subject.scrub_hash input }
    context 'flat' do
      let(:input) { { username: 'user', 'password' => 'pw', age: 35, some: 'other' } }
      it { expect(result).to eq(username: '****', 'password' => '**', age: '**', some: 'other') }
    end
    context 'nested hash' do
      let(:input) { { data: basic, some: 'other' } }
      let(:expected) { { data: basic_cnv, some: 'other' } }
      it { expect(result).to eq(expected) }
    end
    context 'nested array' do
      let(:input) { { data: [basic, basic], some: 'other' } }
      let(:expected) { { data: [basic_cnv, basic_cnv], some: 'other' } }
      it { expect(result).to eq(expected) }
    end
    context 'nested complex' do
      let(:input) { { payload: basic, entries: [basic, basic], some: 'other' } }
      let(:expected) { { entries: [basic_cnv, basic_cnv], payload: basic_cnv, some: 'other' } }
      it { expect(result).to eq(expected) }
    end
    context 'nested complex' do
      let(:keys) do
        %i[
          account_name account_number acct_no address api_access_token authorization_token cvv expiry
          identification_number identity_number name new_account_number new_routing_number password
          password_confirmation password_digest reset_password_token routing_no routing_number secret
          ssn token user zip
        ]
      end
      let(:error) { RuntimeError.new 'oh oh' }
      let(:input) do
        {
          level: 'error',
          # :scope => #<Rollbar::LazyStore:0x00005591fcbfa7f0 @raw={}, @loaded_data={}>,
          exception: error,
          message: 'aem_error_FF-1962',
          extra: {
            payload: {
              account_name: 'some name',
              account_number: '123456',
              routing_number: '7890',
              some: 'other'
            }
          },
          payload: {
            'access_token' => '6afa7b464a6f435698f38559642ca793',
            'data' => {
              timestamp: 1_605_576_279,
              environment: 'staging',
              level: 'error',
              language: 'ruby',
              framework: 'Rails: 5.2.3',
              server: {
                host: 'credit-card-9b59656f-nr9q9',
                root: '/app',
                pid: 143
              },
              notifier: {
                name: 'rollbar-gem',
                version: '2.16.2'
              },
              body: {
                trace: {
                  frames: [],
                  exception: {
                    class: 'RuntimeError',
                    message: 'oh oh',
                    description: 'aem_error_FF-1962'
                  },
                  extra: {
                    payload: {
                      account_name: 'some name',
                      account_number: '123456',
                      routing_number: '7890',
                      some: 'other'
                    }
                  }
                }
              },
              uuid: 'a9a64b62-ccaf-4c80-a77a-a1a381c39710'
            }
          }
        }
      end
      let(:expected) do
        {
          level: 'error',
          # :scope => #<Rollbar::LazyStore:0x00005591fcbfa7f0 @raw={}, @loaded_data={}>,
          exception: error,
          message: 'aem_error_FF-1962',
          extra: {
            payload: {
              account_name: '*********',
              account_number: '******',
              routing_number: '****',
              some: 'other'
            }
          },
          payload: {
            'access_token' => '6afa7b464a6f435698f38559642ca793',
            'data' => {
              timestamp: 1_605_576_279,
              environment: 'staging',
              level: 'error',
              language: 'ruby',
              framework: 'Rails: 5.2.3',
              server: {
                host: 'credit-card-9b59656f-nr9q9',
                root: '/app',
                pid: 143
              },
              notifier: {
                name: '***********',
                version: '2.16.2'
              },
              body: {
                trace: {
                  frames: [],
                  exception: {
                    class: 'RuntimeError',
                    message: 'oh oh',
                    description: 'aem_error_FF-1962'
                  },
                  extra: {
                    payload: {
                      account_name: '*********',
                      account_number: '******',
                      routing_number: '****',
                      some: 'other'
                    }
                  }
                }
              },
              uuid: 'a9a64b62-ccaf-4c80-a77a-a1a381c39710'
            }
          }
        }
      end
      it { expect(result).to eq(expected) }
    end
    context 'double' do
      let(:result) { subject.scrub_keys input, :payload, :data }
      let(:input) { { payload: basic, data: basic, some: 'other' } }
      let(:expected) { { payload: basic_cnv, data: basic_cnv, some: 'other' } }
      it { expect(result).to eq(expected) }
    end
  end
end
