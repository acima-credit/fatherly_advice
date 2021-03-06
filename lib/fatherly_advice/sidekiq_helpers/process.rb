# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    class Process
      include SafeSetter

      attr_reader :orig_process, :hostname, :started_at, :pid, :tag, :concurrency,
                  :queues, :labels, :identity, :busy, :beat, :quiet

      def initialize(process = {})
        @orig_process = process
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

      def each_worker
        workers.values.each { |x| yield x }
      end

      def stuck?
        return false if workers.empty?

        workers.values.all?(&:stuck?)
      end

      def stuck_count
        workers.values.count(&:stuck?)
      end

      delegate :quiet!, :stop!, :dump_threads, :stopping?, to: :orig_process

      def stop_stuck!
        return unless stuck?

        puts format('> stopping %s ...', identity)
        stop!
      end

      def match?(value)
        case value
        when Regexp
          id =~ value
        when String
          id == value || id.index(value)
        else
          false
        end
      end

      def report(size = 90)
        puts format(
          '    %s %s : %i/%i/%i ',
          stuck? ? '[XX]' : '[  ]',
          id,
          busy,
          concurrency,
          stuck_count
        ).ljust(size, '-')

        report_workers(size)
      end

      def report_workers(size)
        if workers.empty?
          puts '        [  ] no workers found!'
        else
          each_worker { |worker| worker.report(size) }
        end
      end

      def inspect
        format '#<%s hostname=%s id=%s>',
               self.class.name,
               hostname.inspect,
               id.inspect
      end

      alias to_s inspect
    end
  end
end
