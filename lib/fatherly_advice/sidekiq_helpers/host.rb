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

      def stuck?
        return false if processes.empty?

        processes.values.all?(&:stuck?)
      end
    end
  end
end
