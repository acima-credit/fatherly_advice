# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::Env, :env_change do
  let(:error_class) { FatherlyAdvice::Error }
  let(:key) { 'SOME_VAR' }
  let(:value) { '123' }
  let(:env) { { key => value, 'OTHER_KEY' => 'true', 'ANOTHER_KEY' => 'false' } }
  subject { described_class }
  context 'get / missing' do
    it('gt same    K') { expect(subject.get(key)).to eq value }
    it('!  same    K') { expect(subject.some_var!).to eq value }
    it('gt symbol  K') { expect(subject.get(:SOME_VAR)).to eq value }
    it('gt changed K') { expect(subject.get('Some_Var')).to eq value }
    it('[] same    K') { expect(subject[key]).to eq value }
    it('[] symbol  K') { expect(subject[:SOME_VAR]).to eq value }
    it('[] changed K') { expect(subject['Some_Var']).to eq value }
    it('. same     K') { expect(subject.some_var).to eq value }
    it('. symbol   K') { expect(subject.SOME_VAR).to eq value }
    it('. changed  K') { expect(subject.Some_Var).to eq value }

    it('[] same    X') { expect(subject['somevar']).to be_nil }
    it('[] symbol  X') { expect(subject[:SOMEVAR]).to be_nil }
    it('[] changed X') { expect(subject['SomeVar']).to be_nil }
    it('. same     X') { expect(subject.somevar).to be_nil }
    it('. symbol   X') { expect(subject.SOMEVAR).to be_nil }
    it('. changed  X') { expect(subject.SomeVar).to be_nil }

    it('[] default D') { expect(subject['somevar', value]).to eq value }
    it('. default  D') { expect(subject.get('somevar', value)).to eq value }
    it('gt missing X') { expect { subject.get!('somevar') }.to raise_error(error_class, "Missing ENV['SOMEVAR']") }
    it('. missing  X') { expect { subject.somevar! }.to raise_error(error_class, "Missing ENV['SOMEVAR']") }
  end
  context '#enabled?' do
    it('uses true   ') { expect(subject.enabled?(:other_key)).to eq true }
    it('uses false  ') { expect(subject.enabled?(:another_key)).to eq false }
    it('uses default') { expect(subject.enabled?(:unknown_var, true)).to eq true }
    it('def to false') { expect(subject.enabled?(:unknown_var)).to eq false }
  end
  context '#disabled?' do
    it('uses true   ') { expect(subject.disabled?(:other_key)).to eq false }
    it('uses false  ') { expect(subject.disabled?(:another_key)).to eq true }
    it('uses default') { expect(subject.disabled?(:unknown_var, true)).to eq true }
    it('def to false') { expect(subject.disabled?(:unknown_var)).to eq false }
  end
  context '#to_i' do
    let(:value) { '5' }
    it('converts to_i  ') { expect(subject.to_i(:some_var)).to eq 5 }
    it('defaults to nil') { expect(subject.to_i(:unknown_var)).to eq nil }
    it('uses defaults  ') { expect(subject.to_i(:unknown_var, 3)).to eq 3 }
  end
  context '#to_f' do
    let(:value) { '5.3' }
    it('converts to_f  ') { expect(subject.to_f(:some_var)).to eq 5.3 }
    it('defaults to nil') { expect(subject.to_f(:unknown_var)).to eq nil }
    it('uses defaults  ') { expect(subject.to_f(:unknown_var, 5.3)).to eq 5.3 }
  end
  context '#check_present!' do
    it('passes') { expect { subject.check_present!(:other_key, :another_key) }.to_not raise_error }
    it('breaks') { expect { subject.check_present!(:xyz) }.to raise_error(FatherlyAdvice::Error) }
  end
end
