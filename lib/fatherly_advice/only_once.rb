# frozen_string_literal: true

module FatherlyAdvice
  class OnlyOnce
    include Logging::Mixin

    class << self
      def instance
        @instance ||= new
      end

      delegate :run, :rerun, :remove, to: :instance
    end

    def initialize
      @jobs = {}
      @ran = Hash.new 0
    end

    def run(name, &blk)
      @jobs[name] ||= blk
      invoke name, false
    end

    def rerun(name)
      invoke name, true
    end

    def remove(name)
      @jobs.delete name
      @ran.delete name
    end

    private

    def invoke(name, force)
      raise "unknown job #{name.inspect}" unless @jobs.key?(name)

      if @ran[name].positive? && !force
        debug 'already ran %s %i times...', name.inspect, @ran[name]
        return
      end

      @ran[name] += 1
      debug 'running %s (%s) for the %s time ...', name.inspect, force ? 'forced' : 'unforced', @ran[name].ordinalize
      @jobs[name].call
    end

    def debug(msg, *args)
      return unless WebServer.debug?

      log_debug "OnlyOnce : #{msg}", *args
    end
  end
end
