# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Style/GlobalVars
RSpec.describe FatherlyAdvice::OnlyOnce, type: :lib do
  describe 'basic' do
    let(:name) { :add_one }
    before(:each) do
      $once_var = 0
      described_class.run(name) { $once_var += 1 }
    end
    it 'adds one only once' do
      expect($once_var).to eq 1
      described_class.run(name) { $once_var += 1 }
      expect($once_var).to eq 1
    end
    it 'does not redefine block' do
      expect($once_var).to eq 1
      described_class.run(name) { $once_var += 2 }
      expect($once_var).to eq 1
    end
    it 'reruns on request but does not redefine' do
      expect($once_var).to eq 1
      described_class.rerun(name) { $once_var += 2 }
      expect($once_var).to eq 2
    end
    after(:each) { described_class.remove name }
  end
end
# rubocop:enable Style/GlobalVars
