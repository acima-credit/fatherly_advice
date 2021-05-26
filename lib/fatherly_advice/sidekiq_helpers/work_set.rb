# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    class WorkSet
      def self.build
        new.build
      end

      def self.ttls
        @ttls ||= {
          default: 3.hours
        }
      end

      def hosts
        @hosts ||= {}
      end

      def ttls
        @ttls ||= self.class.ttls.dup
      end

      def build
        ensure_api_present
        build_hosts
        build_workers
        apply_worker_limits
        self
      end

      def rebuild
        @hosts = {}
        build
      end

      def report(size = 90)
        hosts.values.each do |host|
          banner size, '=', '%s %s ',
                 host.stuck? ? '[XX]' : '[  ]',
                 host.hostname
          report_processes(host, size)
        end
      end

      private

      def ensure_api_present
        sk_present = Object.constants.include? :Sidekiq
        raise 'Sidekiq not present' unless sk_present

        sk = Object.const_get :Sidekiq
        ps_present = sk.constants.include? :ProcessSet
        raise 'Sidekiq::ProcessSet not present' unless ps_present

        ws_present = sk.constants.include? :Workers
        raise 'Sidekiq::ProcessSet not present' unless ws_present

        true
      end

      def build_hosts
        Sidekiq::ProcessSet.new.each do |sidekiq_process|
          process = Process.new sidekiq_process
          hosts[process.hostname] ||= Host.new process.hostname
          hosts[process.hostname].processes[process.identity] = process
        end
      end

      def build_workers
        Sidekiq::Workers.new.each do |process_id, thread_id, work|
          worker = Worker.new process_id, thread_id, work
          hosts.values.each do |host|
            host.processes.values.each do |process|
              next unless process_id == process.identity

              process.workers[worker.thread_id] = worker
            end
          end
        end
      end

      def apply_worker_limits
        hosts.values.each do |host|
          host.processes.values.each do |process|
            process.workers.values.each do |worker|
              worker.ttl = ttls[worker.klass] || ttls[:default]
            end
          end
        end
      end

      def report_processes(host, size)
        if host.processes.empty?
          puts '    [  ] no processes found!'
        else
          host.processes.values.each do |process|
            banner size, '-', '    %s %s : %i/%i/%i ',
                   process.stuck? ? '[XX]' : '[  ]',
                   process.id,
                   process.busy,
                   process.concurrency,
                   process.stuck_count
            report_workers(process)
          end
        end
      end

      def report_workers(process)
        if process.workers.empty?
          puts '        [  ] no workers found!'
        else
          process.workers.values.each do |worker|
            puts format(
              '        %s %s : %-1.1s : %-10.10s : %s %s',
              worker.stuck? ? '[XX]' : '[  ]',
              worker.thread_id,
              worker.short_queue,
              worker.time_ago[0, 15],
              worker.klass,
              worker.args.inspect
            )
          end
        end
      end

      def banner(size, chr, msg, *args)
        puts format(msg, *args).ljust(size, chr)
      end
    end
  end
end
