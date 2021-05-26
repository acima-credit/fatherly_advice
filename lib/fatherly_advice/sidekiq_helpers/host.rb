# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    class Host
      attr_reader :hostname

      def initialize(hostname)
        @hostname = hostname
      end

      def processes
        @processes ||= {}
      end

      def each_process
        processes.values.each { |x| yield x }
      end

      def stuck?
        return false if processes.empty?

        processes.values.all?(&:stuck?)
      end

      def stop_stuck!
        each_process(&:stop_stuck!)
      end

      def report(size = 90)
        puts format(
          '%s %s ',
          stuck? ? '[XX]' : '[  ]',
          hostname
        ).ljust(size, '=')

        report_processes(size)
      end

      def match?(value)
        case value
        when Regexp
          hostname =~ value
        when String
          hostname == value || hostname.index(value)
        else
          false
        end
      end

      def report_processes(size)
        if processes.empty?
          puts '    [  ] no processes found!'
        else
          each_process { |process| process.report(size) }
        end
      end

      def inspect
        format '#<%s hostname=%s>',
               self.class.name,
               hostname.inspect
      end

      alias to_s inspect
    end
  end
end
