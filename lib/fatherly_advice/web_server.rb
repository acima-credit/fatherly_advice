# frozen_string_literal: true

module FatherlyAdvice
  class WebServer
    class << self
      include Util::SafeDependencies

      attr_writer :tld, :domain, :subdomain, :deployment_stage, :root, :parameter_filters

      def app_stage
        Env.get :app_stage, 'development'
      end

      def rails_stage
        return rails.env.to_s if rails

        Env.get :rails_env, app_stage
      end

      def deployment_stage
        @deployment_stage || app_stage
      end

      def local_env
        Env.get :LOCAL_STAGE, app_stage
      end

      def test?
        rails&.env&.test? || rails_stage == 'test'
      end

      def ci?
        app_stage == 'ci' || Env.ci?
      end

      def test_or_ci?
        test? || ci?
      end

      def development?
        app_stage == 'development'
      end

      def staging?
        app_stage == 'staging'
      end

      def production?
        app_stage == 'production'
      end

      def staging_or_production?
        staging? || production?
      end

      def console?
        rails? && !!defined?(::Rails::Console)
      end

      def server?
        rails? && !!defined?(::Rails::Server)
      end

      def debug?
        Env.enabled?(:DEBUG) || console?
      end

      def logger
        if rails?
          ::Rails.logger
        elsif Object.const_defined?(:LOGGER)
          Object.const_get :LOGGER
        else
          Logger.new $stdout
        end
      end

      def tld
        @tld || Env.get(:app_tld, 'dev')
      end

      def domain
        @domain || Env.get(:app_domain, 'missing')
      end

      def subdomain
        @subdomain || Env.get(:app_sub_domain, 'missing')
      end

      def host
        @host ||= Socket.gethostname
      end

      def app_name
        if Object.const_defined?(:APP_NAME)
          Object.const_get :APP_NAME
        elsif rails?
          rails.application.railtie_name.gsub(/_application$/, '')
        else
          subdomain
        end
      end

      def rake?
        File.split($PROGRAM_NAME).last == 'rake'
      end

      def rails_command?
        File.split($PROGRAM_NAME).last == 'rails'
      end

      def sidekiq?
        sidekiq&.server?
      end

      def redis_url
        Env.get :redis_url, 'redis://localhost:6379/0'
      end

      def parameter_filters
        @parameter_filters || rails&.application&.config&.filter_parameters || []
      end

      def root
        @root || rails&.root || Pathname.new('/app')
      end

      def path(*parts)
        root.join(*parts.map(&:to_s))
      end

      def git_revision
        @git_revision ||= `cd #{root} && git rev-parse --short HEAD`.chop
      end

      def file_revision
        @file_revision ||= path('REVISION').exist? ? File.read(path('REVISION')).chop : ''
      end

      def revision
        [git_revision, file_revision, 'NOGIT'].reject(&:empty?).first[0, 9]
      end

      def info_msg
        %(WebServer : domain=#{domain} host=#{host} stage=#{app_stage} env=#{rails_stage})
      end

      def to_s
        %(#<#{info_msg}>)
      end

      alias inspect to_s
    end
  end
end
