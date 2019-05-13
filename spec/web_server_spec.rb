# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::WebServer, :env_change do
  let(:info) { "WebServer : domain=missing host=#{host} stage=development env=development" }
  describe '.app_stage' do
    let(:result) { described_class.app_stage }
    context 'default' do
      it { expect(result).to eq 'development' }
    end
    context 'custom' do
      let(:env) { { app_stage: 'xyz' } }
      it { expect(result).to eq 'xyz' }
    end
  end
  describe '.deployment_stage' do
    let(:result) { described_class.deployment_stage }
    context 'default' do
      it { expect(result).to eq 'development' }
    end
    context 'custom' do
      before { described_class.deployment_stage = 'staging' }
      it { expect(result).to eq 'staging' }
      after { described_class.deployment_stage = nil }
    end
  end
  describe '.rails_stage' do
    let(:result) { described_class.rails_stage }
    context 'rails', :rails do
      let(:env) { { rails_env: 'staging' } }
      it { expect(result).to eq 'staging' }
    end
    context 'default' do
      let(:env) { { app_stage: 'xyz' } }
      it { expect(result).to eq 'xyz' }
    end
    context 'custom' do
      let(:env) { { rails_env: 'abc' } }
      it { expect(result).to eq 'abc' }
    end
  end
  describe '.local_env' do
    let(:result) { described_class.local_env }
    context 'default' do
      let(:env) { { app_stage: 'xyz' } }
      it { expect(result).to eq 'xyz' }
    end
    context 'custom' do
      let(:env) { { local_stage: 'abc' } }
      it { expect(result).to eq 'abc' }
    end
  end
  describe '.test?' do
    let(:result) { described_class.test? }
    context 'rails', :rails do
      let(:env) { { rails_env: 'test' } }
      it { expect(result).to eq true }
    end
    context 'default' do
      let(:env) { { app_stage: 'development' } }
      it { expect(result).to eq false }
    end
    context 'custom' do
      let(:env) { { rails_env: 'test' } }
      it { expect(result).to eq true }
    end
  end
  describe '.ci?' do
    let(:result) { described_class.ci? }
    context 'default' do
      let(:env) { { app_stage: 'ci' } }
      it { expect(result).to eq true }
    end
    context 'custom' do
      let(:env) { { ci: 'true' } }
      it { expect(result).to eq true }
    end
  end
  describe '.test_or_ci?' do
    let(:result) { described_class.test_or_ci? }
    context 'test?' do
      context 'rails', :rails do
        let(:env) { { rails_env: 'test' } }
        it { expect(result).to eq true }
      end
      context 'default' do
        let(:env) { { app_stage: 'development' } }
        it { expect(result).to eq false }
      end
      context 'custom' do
        let(:env) { { rails_env: 'test' } }
        it { expect(result).to eq true }
      end
    end
    context 'ci?' do
      context 'default' do
        let(:env) { { app_stage: 'ci' } }
        it { expect(result).to eq true }
      end
      context 'custom' do
        let(:env) { { ci: 'true' } }
        it { expect(result).to eq true }
      end
    end
  end
  describe '.development?' do
    let(:result) { described_class.development? }
    context 'default' do
      it { expect(result).to eq true }
    end
    context 'custom' do
      let(:env) { { app_stage: 'development' } }
      it { expect(result).to eq true }
    end
  end
  describe '.staging?' do
    let(:result) { described_class.staging? }
    context 'default' do
      it { expect(result).to eq false }
    end
    context 'custom' do
      let(:env) { { app_stage: 'staging' } }
      it { expect(result).to eq true }
    end
  end
  describe '.production?' do
    let(:result) { described_class.production? }
    context 'default' do
      it { expect(result).to eq false }
    end
    context 'custom' do
      let(:env) { { app_stage: 'production' } }
      it { expect(result).to eq true }
    end
  end
  describe '.staging_or_production?' do
    let(:result) { described_class.staging_or_production? }
    context 'staging?' do
      context 'default' do
        it { expect(result).to eq false }
      end
      context 'custom' do
        let(:env) { { app_stage: 'staging' } }
        it { expect(result).to eq true }
      end
    end
    context 'production?' do
      context 'default' do
        it { expect(result).to eq false }
      end
      context 'custom' do
        let(:env) { { app_stage: 'production' } }
        it { expect(result).to eq true }
      end
    end
  end
  describe '.console?' do
    let(:result) { described_class.console? }
    context 'missing' do
      it { expect(result).to eq false }
    end
    context 'present', :rails_console do
      it { expect(result).to eq true }
    end
  end
  describe '.debug?' do
    let(:result) { described_class.debug? }
    context 'missing' do
      it { expect(result).to eq false }
    end
    context 'false' do
      let(:env) { { debug: 'false' } }
      it { expect(result).to eq false }
    end
    context 'true' do
      let(:env) { { debug: 'true' } }
      it { expect(result).to eq true }
    end
    context 'console?', :rails_console do
      it { expect(result).to eq true }
    end
  end
  describe '.tld' do
    let(:result) { described_class.tld }
    context 'default' do
      it { expect(result).to eq 'dev' }
    end
    context 'assigned' do
      before { described_class.tld = 'abc' }
      it { expect(result).to eq 'abc' }
      after { described_class.tld = nil }
    end
    context 'env' do
      let(:env) { { app_tld: 'abc' } }
      it { expect(result).to eq 'abc' }
    end
  end
  describe '.domain' do
    let(:result) { described_class.domain }
    context 'default' do
      it { expect(result).to eq 'missing' }
    end
    context 'assigned' do
      before { described_class.domain = 'abc' }
      it { expect(result).to eq 'abc' }
      after { described_class.domain = nil }
    end
    context 'env' do
      let(:env) { { app_domain: 'abc' } }
      it { expect(result).to eq 'abc' }
    end
  end
  describe '.subdomain' do
    let(:result) { described_class.subdomain }
    context 'default' do
      it { expect(result).to eq 'missing' }
    end
    context 'assigned' do
      before { described_class.subdomain = 'abc' }
      it { expect(result).to eq 'abc' }
      after { described_class.subdomain = nil }
    end
    context 'env' do
      let(:env) { { app_sub_domain: 'abc' } }
      it { expect(result).to eq 'abc' }
    end
  end
  describe '.host' do
    it { expect(described_class.host).to eq host }
  end
  describe '.rake?', :rake do
    it { expect(described_class.rake?).to eq true }
  end
  describe '.rails_command?', :rails_command do
    it { expect(described_class.rails_command?).to eq true }
  end
  describe '.sidekiq?', :sidekiq_server do
    it { expect(described_class.sidekiq?).to eq true }
  end
  describe '.redis_url' do
    let(:result) { described_class.redis_url }
    context 'default' do
      it { expect(result).to eq 'redis://localhost:6379/0' }
    end
    context 'custom' do
      let(:env) { { redis_url: 'redis://localhost:1234/3' } }
      it { expect(result).to eq 'redis://localhost:1234/3' }
    end
  end
  describe '.parameter_filters', :focus2 do
    let(:result) { described_class.parameter_filters }
    context 'missing' do
      it { expect(result).to eq [] }
    end
    context 'assigned' do
      before { described_class.parameter_filters = %i[first_name last_name] }
      it { expect(result).to eq %i[first_name last_name] }
      after { described_class.parameter_filters = nil }
    end
    context 'rails', :rails do
      it { expect(result).to eq %i[first_name last_name] }
    end
  end
  describe '.root' do
    let(:result) { described_class.root }
    context 'default' do
      it { expect(result).to eq Pathname.new('/app') }
    end
    context 'assigned' do
      before { described_class.root = Pathname.new('/mysqpp') }
      it { expect(result).to eq Pathname.new('/mysqpp') }
      after { described_class.root = nil }
    end
    context 'rails', :rails do
      it { expect(result).to eq Pathname.new('/rails/app') }
    end
  end
  describe '.path' do
    let(:result) { described_class.path 'a', 'b' }
    context 'default' do
      it { expect(result).to eq Pathname.new('/app/a/b') }
    end
    context 'assigned' do
      before { described_class.root = Pathname.new('/myqpp') }
      it { expect(result).to eq Pathname.new('/myqpp/a/b') }
      after { described_class.root = nil }
    end
    context 'rails', :rails do
      it { expect(result).to eq Pathname.new('/rails/app/a/b') }
    end
  end
  describe '.info_msg' do
    it { expect(described_class.info_msg).to eq info }
  end
  describe '.to_s' do
    it { expect(described_class.to_s).to eq "#<#{info}>" }
  end
  describe '.inspect' do
    it { expect(described_class.inspect).to eq "#<#{info}>" }
  end
end
