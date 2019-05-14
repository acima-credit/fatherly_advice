# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::Logging::Mixin, :logs, type: :lib do
  let(:example_class) { LoggingHelpers::ExampleLoggingClass }
  let(:logger) { example_class.logger }
  context 'instance' do
    subject { example_class.new }
    context 'host' do
      it { expect(subject.host).to eq host.split('-').last }
    end
    context 'debug' do
      after { expect_logs [:debug, 'LH:ExampleLoggingClass : i : debug : d'] }
      it { subject.do_debug }
    end
    context 'info' do
      after { expect_logs [:info, 'LH:ExampleLoggingClass : i : info : i'] }
      it { subject.do_info }
    end
    context 'error' do
      after { expect_logs [:error, 'LH:ExampleLoggingClass : i : error : e'] }
      it { subject.do_error }
    end
    context 'direct' do
      after { expect_logs [:error, 'LH:ExampleLoggingClass : i : direct : d'] }
      it { subject.log :error, 'i : direct : %s', :d }
    end
    context 'exception', :rails do
      after do
        expect_logs [:error,
                     [%(LH:ExampleLoggingClass : [#{host}] EXCEPTION : RuntimeError : i : Hello! | data : {:a=>"b", :first_name=>"[FILTERED]"} |),
                      %(spec/spec_helper.rb:56:in `do_except')]]
        expect_errors ['RuntimeError', 'i : Hello!', a: 'b', first_name: 'John']
      end
      it { subject.do_except }
    end
    context 'raise and log exception' do
      after do
        expect_logs [:error, %(LH:ExampleLoggingClass : [#{host}] EXCEPTION : RuntimeError : i : Hello! | data : {:a=>"b"})]
        expect_errors ['RuntimeError', 'i : Hello!', a: 'b']
      end
      it { expect { subject.do_except_with_raise }.to raise_error RuntimeError, 'i : Hello!' }
    end
  end
  context 'class' do
    subject { example_class }

    context 'debug' do
      it do
        subject.do_debug
        expect_logs [:debug, 'LH:ExampleLoggingClass : c : debug : d']
      end
    end
    context 'info' do
      after { expect_logs [:info, 'LH:ExampleLoggingClass : c : info : i'] }
      it { subject.do_info }
    end
    context 'error' do
      after { expect_logs [:error, 'LH:ExampleLoggingClass : c : error : e'] }
      it { subject.do_error }
    end
    context 'direct' do
      after { expect_logs [:error, 'LH:ExampleLoggingClass : c : direct : d'] }
      it { subject.log :error, 'c : direct : %s', :d }
    end
    context 'exception' do
      after do
        expect_logs [:error,
                     [%(LH:ExampleLoggingClass : [#{host}] EXCEPTION : RuntimeError : i : Hello! | data : {:a=>"b"}),
                      'spec/spec_helper.rb:79:in']]
        expect_errors ['RuntimeError', 'i : Hello!', a: 'b']
      end
      it { subject.do_except }
    end
    context 'raise and log exception' do
      after do
        expect_logs [:error, %(LH:ExampleLoggingClass : [#{host}] EXCEPTION : RuntimeError : i : Hello! | data : {:a=>"b"})]
        expect_errors ['RuntimeError', 'i : Hello!', a: 'b']
      end
      it { expect { subject.do_except_with_raise }.to raise_error RuntimeError, 'i : Hello!' }
    end
  end
end
