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
        hosts.values.each { |host| yield host }
      end

      def find_host_by(value)
        each_host { |host| return host if host.match?(value) }
        nil
      end

      def each_process
        each_host do |host|
          host.each_process { |process| yield process }
        end
      end

      def find_process_by(value)
        each_process { |process| return process if process.match?(value) }
        nil
      end

      def each_worker
        each_process do |process|
          process.each_worker { |worker| yield worker }
        end
      end

      def find_worker_by(value)
        each_worker { |worker| return worker if worker.match?(value) }
        nil
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

      def process_set
        ensure_api_present
        Sidekiq::ProcessSet.new
      end

      delegate :cleanup, :size, :leader, to: :process_set, prefix: :process_set

      def worker_set
        ensure_api_present
        Sidekiq::Workers.new
      end

      delegate :size, to: :worker_set, prefix: :worker_set

      def rebuild
        @hosts = {}
        build
      end

      def stop_stuck!
        each_host(&:stop_stuck!)
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
        process_set.each do |sidekiq_process|
          process = Process.new sidekiq_process
          hosts[process.hostname] ||= Host.new process.hostname
          hosts[process.hostname].processes[process.identity] = process
        end
      end

      def build_workers
        worker_set.each do |process_id, thread_id, work|
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
