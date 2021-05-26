# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    class Worker
      include SafeSetter
      attr_reader :process_id, :thread_id, :queue, :klass, :args, :retry,
                  :created_at, :bid, :enqueued_at, :run_at
      attr_accessor :ttl

      def initialize(process_id, thread_id, work)
        @process_id = process_id
        @thread_id = thread_id
        @queue = set(work['queue'], :string) || set(work.dig('payload', 'queue'), :string, 'missing')
        @klass = set work.dig('payload', 'class'), :string
        @args = work.dig('payload', 'args')
        @retry = set work.dig('payload', 'retry'), :boolean
        @created_at = set work.dig('payload', 'created_at'), :time
        @bid = set work.dig('payload', 'bid'), :string
        @enqueued_at = set work.dig('payload', 'enqueued_at'), :time
        @run_at = set work['run_at'], :time
      end

      def short_queue
        queue.to_s.
          gsub(/priority/i, '').
          gsub(/queue/i, '').
          split('_').
          map { |x| x[0, 1] }.
          join.
          upcase
      end

      def time_ago_parts(from_time = Time.current)
        diff = from_time - run_at

        day = 24 * 60 * 60
        days = diff.to_i / day

        diff2 = diff - (days * day)
        hour = 60 * 60
        hours = diff2.to_i / hour

        diff3 = diff2 - (hours * hour)
        minute = 60
        minutes = diff3.to_i / minute

        seconds = diff3.to_i - (minutes * minute)
        [days, hours, minutes, seconds]
      end

      def time_ago(from_time = Time.current)
        days, hours, minutes, seconds = time_ago_parts(from_time)

        msg = []
        msg.push("#{days}d") if days.positive?
        msg.push("#{hours}h") if hours.positive?
        msg.push("#{minutes}m") if minutes.positive?
        msg.push("#{seconds}s") if seconds.positive?
        msg.join(' ')
      end

      def stuck?(from_time = Time.current)
        return false unless ttl.present?

        deadline = run_at + ttl
        from_time > deadline
      end

      def match?(value)
        case value
        when Regexp
          thread_id =~ value
        when String
          thread_id == value || thread_id.index(value)
        else
          false
        end
      end

      def report(_size = 90)
        puts format(
          '        %s %s (%-1.1s) %-10.10s : %s %s',
          stuck? ? '[XX]' : '[  ]',
          thread_id,
          short_queue,
          time_ago[0, 15],
          klass,
          args.inspect
        )
      end

      def inspect
        format '#<%s thread_id=%s stuck=%s time_ago=%s klass=%s>',
               self.class.name,
               thread_id.inspect,
               stuck?.inspect,
               time_ago.inspect,
               klass.inspect
      end

      alias to_s inspect
    end
  end
end
