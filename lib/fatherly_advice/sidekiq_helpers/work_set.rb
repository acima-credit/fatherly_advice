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

      def each_host
        hosts.values.each { |x| yield x }
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

      def stop_stuck?
        each_host(&:stop_stuck?)
      end

      def report(size = 90)
        each_host { |host| host.report size }
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
          each_host do |host|
            host.each_process do |process|
              next unless process_id == process.identity

              process.workers[worker.thread_id] = worker
            end
          end
        end
      end

      def apply_worker_limits
        each_host do |host|
          host.each_process do |process|
            process.each_worker do |worker|
              worker.ttl = ttls[worker.klass] || ttls[:default]
            end
          end
        end
      end
    end
  end
end
