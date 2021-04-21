# frozen_string_literal: true

RSpec.describe FatherlyAdvice do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  it 'has module names' do
    expect(described_class.modules.keys).to eq %i[
      env
      web_server
      simple_hash
      logging
      only_once
      site_settings
      enums
      json_web_token
    ]
  end

  it 'loads some extensions', :constants do
    expect(Object.const_defined?(:WebServer)).to eq false
    expect(Object.const_defined?(:SimpleHash)).to eq false

    described_class.ext :web_server, :simple_hash

    expect(WebServer).to eq FatherlyAdvice::WebServer
    expect(SimpleHash).to eq FatherlyAdvice::SimpleHash

    expect(Object.const_defined?(:Env)).to eq false
    expect(Object.const_defined?(:Logging)).to eq false
    expect(Object.const_defined?(:OnlyOnce)).to eq false
    expect(Object.const_defined?(:SiteSettings)).to eq false
  end

  it 'loads all extensions', :constants do
    expect(Object.const_defined?(:Env)).to eq false
    expect(Object.const_defined?(:WebServer)).to eq false
    expect(Object.const_defined?(:SimpleHash)).to eq false
    expect(Object.const_defined?(:Logging)).to eq false
    expect(Object.const_defined?(:OnlyOnce)).to eq false
    expect(Object.const_defined?(:SiteSettings)).to eq false

    described_class.ext_all

    expect(Env).to eq FatherlyAdvice::Env
    expect(WebServer).to eq FatherlyAdvice::WebServer
    expect(SimpleHash).to eq FatherlyAdvice::SimpleHash
    expect(Logging).to eq FatherlyAdvice::Logging
    expect(OnlyOnce).to eq FatherlyAdvice::OnlyOnce
    expect(SiteSettings).to eq FatherlyAdvice::SiteSettings
  end
end
