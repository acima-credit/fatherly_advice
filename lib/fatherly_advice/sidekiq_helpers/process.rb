# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    class Process
      include SafeSetter

      attr_reader :hostname, :started_at, :pid, :tag, :concurrency,
                  :queues, :labels, :identity, :busy, :beat, :quiet

      def initialize(process = {})
        @hostname = set process['hostname'], :string, 'missing'
        @started_at = set process['started_at'], :time
        @hostname = set process['hostname'], :string
        @started_at = set process['started_at'], :time
        @pid = set process['pid'], :integer
        @tag = set process['tag'], :string
        @concurrency = set process['concurrency'], :integer
        @queues = set process['queues'], :string_array
        @labels = set process['labels'], :string_array
        @identity = set process['identity'], :string, 'missing:missing'
        @busy = set process['busy'], :integer
        @beat = set process['beat'], :time
        @quiet = set process['quiet'], :boolean
      end

      def id
        identity.split(':').last
      end

      def workers
        @workers ||= {}
      end

      def stuck?
        return false if workers.empty?

        workers.values.all?(&:stuck?)
      end

      def stuck_count
        workers.values.count(&:stuck?)
      end
    end
  end
end
