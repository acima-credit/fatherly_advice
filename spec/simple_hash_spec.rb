# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::SimpleHash, type: :lib do
  describe 'instance' do
    let(:attrs) do
      {
        a: 1,
        b: 'dos',
        c: { d: 3.5 },
        e: [4, 5, 6],
        f: { g: { h: 7 }, i: [8, 9] },
        j: [{ k: 10 }, { l: 11 }],
        k?: 'question'
      }
    end
    subject { described_class.new attrs }

    let(:exp_values) do
      [1, 'dos', { d: 3.5 }, [4, 5, 6], { g: { h: 7 }, i: [8, 9] }, [{ k: 10 }, { l: 11 }], 'question']
    end
    let(:exp_json) do
      '{"a":1,"b":"dos","c":{"d":3.5},"e":[4,5,6],"f":{"g":{"h":7},"i":[8,9]},"j":[{"k":10},{"l":11}],"k?":"question"}'
    end

    it('[:a]       ') { expect(subject[:a]).to eq 1 }
    it("['a']      ") { expect(subject['a']).to eq 1 }
    it('try(:ab)   ') { expect(subject.try(:ab)).to be_nil }
    it('.ab        ') { expect { subject.ab }.to raise_error NoMethodError }
    it('.a.b       ') { expect { subject.a.b }.to raise_error NoMethodError }
    it('.a?        ') { expect { subject.a? }.to raise_error NoMethodError }
    it('.b         ') { expect(subject.b).to eq 'dos' }
    it('dig(:c, :d)') { expect(subject.dig(:c, :d)).to eq 3.5 }
    it('.c.d)      ') { expect(subject.c.d).to eq 3.5 }
    it('e.first     ') { expect(subject.e.first).to eq 4 }
    it('e.last     ') { expect(subject.e.last).to eq 6 }
    it('e[1]       ') { expect(subject.e[1]).to eq 5 }
    it('f.g.h      ') { expect(subject.f.g.h).to eq 7 }
    it('f.g[:h]    ') { expect(subject.f.g[:h]).to eq 7 }
    it('f[:g][:h]  ') { expect(subject.f[:g][:h]).to eq 7 }
    it('j.first.k   ') { expect(subject.j.first.k).to eq 10 }
    it('j.last.l   ') { expect(subject.j.last.l).to eq 11 }
    it('k?         ') { expect(subject.k?).to eq 'question' }
    it('keys       ') { expect(subject.keys).to eq(%i[a b c e f j k?]) }
    it('values     ') { expect(subject.values).to eq(exp_values) }
    it('values     ') { expect(subject.to_json).to eq(exp_json) }
  end
end

RSpec.describe FatherlyAdvice::SimpleHash::Serializer, type: :lib do
  describe '.dump' do
    let(:input) { FatherlyAdvice::SimpleHash.new a: 1, b: 2 }
    let(:result) { described_class.dump input }
    it('class') { expect(result.class.name).to eq 'Hash' }
    it('inspect') { expect(result.inspect).to eq '{:a=>1, :b=>2}' }
  end
  describe '.load' do
    let(:input) { { a: 1, b: 2 } }
    let(:result) { described_class.load input }
    it('class') { expect(result.class.name).to eq 'FatherlyAdvice::SimpleHash' }
    it('inspect') { expect(result.inspect).to eq '{:a=>1, :b=>2}' }
  end
end
