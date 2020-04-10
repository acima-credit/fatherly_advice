# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::Enums, :focus do
  subject { described_class.build :a, 'z', 'some', y: 'YES', b: 'bee' }
  context 'basics' do
    it { expect(subject).to be_a Module }
  end
  context 'constants' do
    it { expect(subject.constants.sort).to eq %i[A B SOME Y Z] }
    it { expect(subject::A).to eq 'a' }
    it { expect(subject::Z).to eq 'z' }
    it { expect(subject::SOME).to eq 'some' }
    it { expect(subject::Y).to eq 'yes' }
    it { expect(subject::B).to eq 'bee' }
  end
  context 'helpers' do
    it { expect(subject.keys).to eq %w[A Z SOME Y B] }
    it { expect(subject.values).to eq %w[a z some yes bee] }
    it { expect(subject.to_h).to eq('A' => 'a', 'Z' => 'z', 'SOME' => 'some', 'Y' => 'yes', 'B' => 'bee') }
  end
  context 'aliases' do
    it { expect(subject.a).to eq 'a' }
    it { expect(subject.z).to eq 'z' }
    it { expect(subject.some).to eq 'some' }
    it { expect(subject.y).to eq 'yes' }
    it { expect(subject.b).to eq 'bee' }
  end
end
