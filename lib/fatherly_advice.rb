# frozen_string_literal: true

require 'socket'
require 'pathname'
require 'logger'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflector/methods'
require 'active_support/core_ext/integer/inflections'
require 'action_dispatch/http/parameter_filter'

module FatherlyAdvice
  class Error < StandardError; end
end

require 'fatherly_advice/version'
require_relative 'fatherly_advice/util'
require_relative 'fatherly_advice/env'
require_relative 'fatherly_advice/web_server'
require_relative 'fatherly_advice/simple_hash'
require_relative 'fatherly_advice/logging'
require_relative 'fatherly_advice/only_once'
