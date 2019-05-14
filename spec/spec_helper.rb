# frozen_string_literal: true

require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'rspec/core/shared_context'
require 'json'
require 'fatherly_advice'

ROOT = Pathname.new(__FILE__).expand_path.dirname.dirname

RSpec.configure do |config|
  config.default_formatter = :documentation if ENV['PRETTY']
  config.filter_run focus: true if ENV['FOCUS'].to_s == 'true'
  config.disable_monkey_patching!

  config.run_all_when_everything_filtered     = true
  config.example_status_persistence_file_path = '.rspec_status'
  config.shared_context_metadata_behavior     = :apply_to_host_groups
  config.profile_examples                     = 3
  config.order                                = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
    c.syntax                                               = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

require 'active_support/string_inquirer'
require 'active_support/core_ext/object/blank'

module LoggingHelpers
  class ExampleLoggingClass
    include FatherlyAdvice::Logging::Mixin

    def do_debug
      log_debug 'i : debug : %s', :d
    end

    def do_info
      log_info 'i : info : %s', :i
    end

    def do_error
      log_error 'i : error : %s', :e
    end

    def do_except
      raise 'i : Hello!'
    rescue StandardError => e
      log_exception e, a: 'b', first_name: 'John'
    end

    def do_except_with_raise
      log_and_raise_exception 'i : Hello!', a: 'b'
    end

    class << self
      def do_debug
        log_debug 'c : debug : %s', :d
      end

      def do_info
        log_info 'c : info : %s', :i
      end

      def do_error
        log_error 'c : error : %s', :e
      end

      def do_except
        raise 'i : Hello!'
      rescue StandardError => e
        log_exception e, a: 'b'
      end

      def do_except_with_raise
        log_and_raise_exception 'i : Hello!', a: 'b'
      end
    end
  end
  class MemoryLogger
    attr_reader :entries

    def initialize
      @entries = []
    end

    def unknown(msg)
      log :unknown, msg
    end

    def fatal(msg)
      log :fatal, msg
    end

    def error(msg)
      log :error, msg
    end

    def warn(msg)
      log :warn, msg
    end

    def info(msg)
      log :info, msg
    end

    def debug(msg)
      log :debug, msg
    end

    def log(type, msg)
      @entries << [type, msg]
    end
  end
  class ErrorReporter
    attr_reader :entries

    def initialize
      @entries = []
    end

    def error(e, data = {})
      entries << { exception: e, data: data }
    end

    delegate :size, :clear, to: :entries
  end

  extend RSpec::Core::SharedContext

  let(:example_class) { described_class }
  let(:logger) { example_class.logger }
  let(:host) { Socket.gethostname.split('-').last }

  def compare_log_entry(type, msg, exp_type, exp_msg)
    return false unless type == exp_type

    case exp_msg
    when Array
      exp_msg.all? do |msg_partial|
        if msg_partial.is_a? Regexp
          msg.match?(msg_partial)
        else
          msg.index(msg_partial.to_s).present?
        end
      end
    else
      msg == exp_msg
    end
  end

  def expect_log(exp_type, exp_msg)
    expect(logger.provider).to be_a MemoryLogger

    found = logger.entries.find { |type, msg| compare_log_entry type, msg, exp_type, exp_msg }
    expect(found).to be_present, "expected to find #{exp_type.inspect} log\n  with message [#{exp_msg}]\n  but was not found"
  end

  def expect_logs(*tuples)
    expect(logger.provider).to be_a MemoryLogger

    debug_logs

    act_size = logger.entries.size
    exp_size = tuples.size
    expect(act_size).to eq(exp_size), format('expected to have %i log entries but found %i', exp_size, act_size)

    tuples.each_with_index do |(exp_type, exp_msg), idx|
      act_type, act_msg = logger.entries[idx]
      expect(act_type).to eq(exp_type), format('expected log[%i] meth to be %s but was %s', idx, exp_type.inspect, act_type.inspect)
      msg_match = compare_log_entry act_type, act_msg, exp_type, exp_msg
      expect(msg_match).to eq(true), format("expected log[%i] message\n  to be   [%s]\n  but was [%s]", idx, exp_msg.inspect, act_msg)
    end
  end

  def debug_logs
    return unless FatherlyAdvice::Env.debug_test_logs?

    logger.entries.each_with_index do |(type, msg), idx|
      puts format('%2i : log > %-6.6s : %s', idx, type, msg)
    end
  end

  def expect_errors(*tuples)
    reporter = logger.error_reporter
    expect(reporter).to be_a ErrorReporter

    debug_errors

    act_size = reporter.entries.size
    exp_size = tuples.size
    expect(act_size).to eq(exp_size), format('expected to have %i error entries but found %i', exp_size, act_size)

    tuples.each_with_index do |(exp_exc_type, exp_exc_msg, exp_hsh), idx|
      act_hsh = reporter.entries[idx]
      act_exc = act_hsh[:exception]
      act_data = act_hsh[:data]
      expect(act_exc.class.name).to eq(exp_exc_type.to_s) if exp_exc_type
      expect(act_exc.message).to eq(exp_exc_msg) if exp_exc_msg
      expect(act_data).to eq(exp_hsh) if exp_hsh
    end
  end

  def debug_errors
    return unless FatherlyAdvice::Env.debug_test_logs?

    logger.error_reporter.entries.each_with_index do |hsh, idx|
      puts format('%2i : error > %s : %-20.20s : %s', idx, hsh[:exception].class.name, hsh[:exception].message[0, 20], hsh[:data].inspect)
    end
  end
end

RSpec.configure do |config|
  config.include LoggingHelpers, :logs
  config.around(:example, logs: true) do |example|
    old_root                       = FatherlyAdvice::WebServer.root
    FatherlyAdvice::WebServer.root = ROOT

    logger          = example_class.logger
    old_provider    = logger.provider_type == :custom ? logger.provider : nil
    old_reporter    = logger.error_reporter
    logger.provider = LoggingHelpers::MemoryLogger.new
    logger.error_reporter = LoggingHelpers::ErrorReporter.new

    example.run

    logger.provider = old_provider
    logger.error_reporter = old_reporter

    FatherlyAdvice::WebServer.root = old_root
  end
end

module EnvHelpers
  def change_env_set(set)
    return false unless block_given?

    previous = {}
    set.each do |name, value|
      new_name           = name.to_s.upcase
      previous[new_name] = ENV[new_name]
      if value.nil?
        ENV.delete new_name
      else
        ENV[new_name] = value.to_s
      end
    end

    res = yield

    previous.each do |name, value|
      ENV[name] = value
    end

    res
  end

  extend RSpec::Core::SharedContext

  let(:env) { {} }
end

RSpec.configure do |config|
  config.include EnvHelpers
  config.around(:example, env_change: true) do |example|
    change_env_set(env) { example.run }
  end
end

module GeneralHelpers
  extend RSpec::Core::SharedContext
  let(:host) { Socket.gethostname }
end

RSpec.configure do |config|
  config.include GeneralHelpers
  config.before(:example, constants: true) do
    FatherlyAdvice.modules.keys.each do |key|
      name = key.to_s.camelize
      Object.send(:remove_const, name) if Object.const_defined?(name)
    end
  end
end

module RailsHelpers
  class RailsMock
    class Console
    end

    def initialize(fields = {})
      fields.each { |k, v| instance_variable_set "@#{k}", v }
    end

    def env
      @env ||= ActiveSupport::StringInquirer.new(ENV['RAILS_ENV'].presence || ENV['RACK_ENV'].presence || 'development')
    end

    def root
      @root ||= Pathname.new '/rails/app'
    end

    def application
      @application ||= FatherlyAdvice::SimpleHash.new config: { filter_parameters: %i[first_name last_name] }
    end
  end
  class SidekiqMock
    def self.server?
      true
    end
  end

  extend RSpec::Core::SharedContext

  let(:rails_options) { {} }
  let(:rails_mock) { RailsMock.new rails_options }
end

RSpec.configure do |config|
  config.include RailsHelpers, :rails
  config.include RailsHelpers, :rails_console
  config.before(:example, rails: true) do
    stub_const 'Rails', RailsHelpers::RailsMock.new
  end
  config.before(:example, rails_console: true) do
    stub_const 'Rails::Console', Class.new
  end
  config.around(:example, rake: true) do |example|
    old           = $PROGRAM_NAME
    $PROGRAM_NAME = '/app/bin/rake'
    example.run
    $PROGRAM_NAME = old
  end
  config.around(:example, rails_command: true) do |example|
    old           = $PROGRAM_NAME
    $PROGRAM_NAME = '/app/bin/rails'
    example.run
    $PROGRAM_NAME = old
  end
  config.before(:example, sidekiq_server: true) { stub_const 'Sidekiq', RailsHelpers::SidekiqMock }
end
