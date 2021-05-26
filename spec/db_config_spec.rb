# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::DbConfig do
  before(:all) { described_class.model ConfigDefault }
  before(:each) do
    subject.delete_all
    subject.cache.clear
  end

  shared_examples_for 'a DB config' do
    describe '.default_by_name' do
      it 'finds a set value' do
        subject.create(name: 'test', value: 'test')

        expect(subject.default_by_name('test')).to eql('test')
      end

      it 'finds a set value not the default' do
        subject.create(name: 'test2', value: 'test2')

        expect(subject.default_by_name('test2', 'test')).to eql('test2')
      end

      it 'errors when no default is passed in on an unset config' do
        error_class = subject::DefaultNotConfigured
        error_msg = 'default value not configured for test3'

        expect { subject.default_by_name('test3') }.to raise_error(error_class, error_msg)
      end

      it 'returns the default and sets the value in the db' do
        expect(subject.default_by_name('test4', 'test4')).to eql('test4')
      end
    end

    describe '.update_by_name' do
      it 'updates the value in the db' do
        subject.create(name: 'test', value: 'test')
        subject.update_by_name('test', 'test2')
        expect(subject.default_by_name('test')).to eql('test2')
      end

      it 'creates a new value in the db' do
        subject.update_by_name('test', 'test')
        expect(subject.default_by_name('test')).to eql('test')
      end
    end

    describe '.add_array_entry_by_name' do
      it 'updates the value in the db' do
        subject.create(name: 'test_ary', value: 'test1,test2')

        expect(subject.add_array_entry_by_name('test_ary', 'test3')).to eql('test3')
        expect(subject.default_by_name('test_ary')).to eql('test1,test2,test3')
      end

      it 'creates a new value in the db' do
        expect(subject.add_array_entry_by_name('test_ary', 'test3')).to eql('test3')
        expect(subject.default_by_name('test_ary')).to eql('test3')
      end
    end

    describe '.default_array_by_name' do
      it 'updates the value in the db' do
        subject.create(name: 'test_ary', value: 'test1,test2')

        expect(subject.default_array_by_name('test_ary', ['test3'])).to eql(%w[test1 test2])
      end

      context 'creates a new value in the db' do
        it 'from array' do
          expect(subject.default_array_by_name('test_ary', ['test3'])).to eql(['test3'])
        end
        it 'from args' do
          expect(subject.default_array_by_name('test_ary', 'test3')).to eql(['test3'])
        end
      end
    end

    describe '.cached_by_name' do
      let(:cache) { described_class.cache }
      let(:name) { format 'random_%s_key', SecureRandom.hex(3) }
      let(:pre_value) { '123' }
      let(:value) { '456' }

      let(:result) { subject.cached_by_name name, value }

      context 'with existing entry in cache' do
        context 'when active' do
          it 'returns the cache value without checking the db' do
            subject.create name: name, value: value
            cache.write name, pre_value

            ff_time(30.seconds) { expect(result).to eq pre_value }
          end
        end
        context 'when expired' do
          it 'returns the cache value without checking the db' do
            ff_time(65.seconds) { expect(result).to eq value }
          end
        end
      end
      context 'without existing entry in the cache' do
        context 'and without an entry in the db' do
          before do
            expect(subject).to receive(:create).with(name: name, value: value).and_call_original
          end
          it 'returns the value without checking' do
            expect(subject.cached_by_name(name, value)).to eq value
          end
        end
        context 'and with an entry in the db' do
          before do
            subject.create name: name, value: pre_value
            expect(subject).to_not receive(:create)
          end
          it 'returns the value without checking' do
            expect(subject.cached_by_name(name, value)).to eq pre_value
          end
        end
      end
    end

    describe '.remove' do
      it 'deletes an entry from the db and cache' do
        subject.create name: 'test', value: 'test'
        subject.cache.write 'test', 'test'

        subject.remove 'test'

        expect(subject.find_by(name: 'test')).to be_nil
        expect(subject.cache.fetch('test')).to be_nil
      end

      it 'does not throw an error on db miss' do
        subject.cache.write 'test', 'test'

        expect { subject.remove 'test' }.to_not raise_error

        expect(subject.find_by(name: 'test')).to be_nil
        expect(subject.cache.fetch('test')).to be_nil
      end

      it 'does not throw an error on cache miss' do
        subject.create name: 'test', value: 'test'

        expect { subject.remove 'test' }.to_not raise_error

        expect(subject.find_by(name: 'test')).to be_nil
        expect(subject.cache.fetch('test')).to be_nil
      end

      it 'does not throw an error on both db and cache miss' do
        expect { subject.remove 'test' }.to_not raise_error

        expect(subject.find_by(name: 'test')).to be_nil
        expect(subject.cache.fetch('test')).to be_nil
      end
    end
  end

  context 'on the module' do
    subject { described_class }
    it_behaves_like 'a DB config'
  end

  context 'on the model' do
    subject { ConfigDefault }
    it_behaves_like 'a DB config'
  end
end
