# frozen_string_literal: true

module FatherlyAdvice
  module Logging
    class Formatter < ::Logger::Formatter
      FORMAT = "%-5.5s : %s\n"

      def call(severity, _time, _progname, msg)
        format(FORMAT, severity[0, 5], msg2str(msg))
      end
    end

    module Mixin
      def self.included(base)
        base.extend Util::ParameterFiltering
        base.extend ClassMethods
      end

      def logger
        self.class.logger
      end

      def logger=(value)
        self.class.logger = value
      end

      def log_debug(*args)
        self.class.log_debug(*args)
      end

      def log_info(*args)
        self.class.log_info(*args)
      end

      def log_error(*args)
        self.class.log_error(*args)
      end

      def log(*args)
        self.class.log(*args)
      end

      def log_exception(*args)
        self.class.log_exception(*args)
      end

      def log_and_raise_exception(*args)
        self.class.log_and_raise_exception(*args)
      end

      def host
        self.class.host
      end

      module ClassMethods
        def logger_name
          return @logger_name if instance_variable_defined?(:@logger_name)

          parts        = name.split('::')
          pref, post   = parts.last == 'Job' ? [parts[0..-3], parts[-2, 2]] : [parts[0..-2], parts[-1, 1]]
          @logger_name = (pref.map { |x| x.underscore.split('_').map { |y| y[0..0].upcase }.join } + post).join(':')
        end

        def logger
          @logger || ::FatherlyAdvice::Logging.instance
        end

        def logger=(value)
          @logger = value
        end

        def log_debug(message, *args)
          log :debug, message, *args
        end

        def log_info(message, *args)
          log :info, message, *args
        end

        def log_error(message, *args)
          log :error, message, *args
        end

        def log(*args)
          if args.first.is_a?(Symbol)
            type, message, *args = args
          elsif args.first.is_a?(String)
            message, type, *args = args
          else
            type, message, *args = :error, 'could not log with %s', args.inspect
          end
          log_formatted type, "#{logger_name} : #{message}", *args
        end

        def log_exception(e, data = {})
          msg = "[#{host}] EXCEPTION : #{e.class.name} : #{e.message}"
          msg += " | data : #{safe_arg_hash(data)}" if data.present?
          msg += " | #{clean_backtrace(e)}" if e.backtrace
          log(:error, msg).tap { logger&.report_error e, data }
        end

        def log_and_raise_exception(e, data = {})
          e = RuntimeError.new(e) if e.is_a?(String)
          log_exception e, data
          raise e
        end

        def host
          @host ||= Socket.gethostname.split('-').last
        end

        private

        def log_formatted(type, msg, *args)
          args = args.map { |x| safe_arg_value(x) }
          logger.send type, format(msg, *args)
        end

        def gem_prefix_ignored
          @gem_prefix_ignored ||= Gem.bin_path('rake', 'rake').split('/rake-').first
        end

        def clean_backtrace(e, size = 6)
          e.backtrace.
            reject { |x| x.start_with?(gem_prefix_ignored) }[0, size].
            map { |x| x.gsub(WebServer.root.to_s + '/', '') }.
            join(' : ')
        end
      end
    end

    class SwitchableLogger
      attr_writer :provider, :error_reporter

      def initialize(provider = nil)
        @provider = provider
      end

      def provider
        @provider || rails_logger || stdout_logger
      end

      def error_reporter
        @error_reporter
      end

      def report_error(e, data = {})
        error_reporter&.error e, data
      end

      def provider_type
        return :custom if @provider

        rails_logger ? :rails : :stdout
      end

      def host
        @host ||= Socket.gethostname.split('-').last
      end

      def method_missing(meth, *args, &block)
        if provider.respond_to?(meth)
          provider.send(meth, *args, &block)
        elsif provider.respond_to?("log_#{meth}")
          provider.send("log_#{meth}", *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(meth, include_private = false)
        return true if provider.respond_to?(meth) || provider.respond_to?("log_#{meth}")

        super
      end

      def switch_to_file(name = 'app.log')
        @provider = file_logger name
      end

      def switch_to_stdout
        @provider = stdout_logger
      end

      def to_s
        format '#<%s @provider=%s>', self.class.name, provider_type.inspect
      end

      alias inspect to_s

      private

      def rails_logger
        rails&.logger
      end

      def rails
        Object.const_defined?(:Rails) ? Object.const_get(:Rails) : nil
      end

      def stdout_logger
        ::ActiveSupport::Logger.new(STDOUT).tap(&method(:set_logger_options))
      end

      def file_logger(name)
        ::Logger.new(default_logger_path(name)).tap(&method(:set_logger_options))
      end

      def default_logger_path(name = 'app.log')
        Pathname.new(__FILE__).dirname.dirname.join 'log', name
      end

      def set_logger_options(instance, level = ::Logger::INFO)
        instance.level = level
        instance.formatter = ::Logging.formatter
      end
    end

    module_function

    def instance
      @instance ||= SwitchableLogger.new
    end

    def provider
      instance.provider
    end

    def formatter
      @formatter ||= Formatter.new
    end
  end
end
