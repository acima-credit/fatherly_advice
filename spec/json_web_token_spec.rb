# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::JsonWebToken, type: :lib do
  context 'default_request_options' do
    subject { described_class.default_request_options }
    let(:options) do
      {
        connect_timeout: 2,
        headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' },
        read_timeout: 2,
        ssl_verify_peer: true,
        write_timeout: 2
      }
    end
    it { expect(subject).to eq(options) }
  end
  context 'request' do
    let(:path) { 'http://example.com' }
    before { expect(Excon).to receive(:get).with(path, described_class.default_request_options) }
    it { described_class.request :get, path }
  end
  context 'local_cache' do
    subject { described_class.local_cache }
    it { expect(subject).to be_a Hash }
    it { expect(subject).to be_empty }
  end
  context 'shared_cache_options' do
    subject { described_class.shared_cache_options }
    let(:options) do
      {
        expires_in: 60.minutes,
        namespace: 'missing:jwt:cache',
        race_condition_ttl: 3.seconds,
        url: 'redis://localhost:6379/5'
      }
    end
    it { expect(subject).to be_a Hash }
    it { expect(subject).to eq options }
  end
  context 'shared_cache' do
    subject { described_class.shared_cache }
    it { expect(subject).to be_a ActiveSupport::Cache::RedisCacheStore }
  end
  context 'clear_cache' do
    before do
      expect(described_class.local_cache).to receive(:clear)
      expect(described_class.shared_cache).to receive(:clear)
    end
    it { described_class.clear_cache }
  end
  context 'configure' do
    let(:options) { FatherlyAdvice::SimpleHash.new server: described_class::Server, client: described_class::Client }
    it do
      expect { |b| described_class.configure(&b) }.to yield_with_args(options)
    end
  end
end
