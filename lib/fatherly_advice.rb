# frozen_string_literal: true

require 'socket'
require 'pathname'
require 'logger'
require 'zlib'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflector/methods'
require 'active_support/core_ext/integer/inflections'
require 'active_support/cache'
require 'active_support/cache/redis_cache_store'
require 'active_support/core_ext/date'
require 'active_support/core_ext/numeric/time'
require 'active_support/notifications'
require 'jwt'
require 'excon'

module FatherlyAdvice
  class Error < StandardError
  end
end

require 'fatherly_advice/version'
require_relative 'fatherly_advice/util'
require_relative 'fatherly_advice/env'
require_relative 'fatherly_advice/web_server'
require_relative 'fatherly_advice/simple_hash'
require_relative 'fatherly_advice/logging'
require_relative 'fatherly_advice/only_once'
require_relative 'fatherly_advice/enums'
require_relative 'fatherly_advice/scrubber'
require_relative 'fatherly_advice/json_web_token'
require_relative 'fatherly_advice/db_config'
require_relative 'fatherly_advice/sidekiq_helpers'

module FatherlyAdvice
  def self.modules
    @modules ||= SimpleHash.new env: Env,
                                web_server: WebServer,
                                simple_hash: SimpleHash,
                                logging: Logging,
                                only_once: OnlyOnce,
                                site_settings: SiteSettings,
                                enums: Enums,
                                json_web_token: JsonWebToken,
                                db_config: DbConfig,
                                sidekiq_helpers: SidekiqHelpers
  end

  def self.ext(*keys)
    keys = modules.keys if keys == [:all]

    keys.flatten.each do |key|
      raise "unknown module [#{key}]" unless modules.key?(key)

      name = key.to_s.camelize
      Object.send(:remove_const, name) if Object.const_defined? name

      Object.const_set name, modules[key]
    end
  end

  def self.ext_all
    ext modules.keys
  end
end
