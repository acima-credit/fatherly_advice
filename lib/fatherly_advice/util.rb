# frozen_string_literal: true

module FatherlyAdvice
  module Util
    module ParameterFiltering
      def filter_params(hsh)
        filters = Rails.application.config.filter_parameters
        ::ActionDispatch::Http::ParameterFilter.new(filters).filter hsh
      end

      def filter_args(args)
        args.map { |x| safe_arg_value x }
      end

      def safe_arg_value(value)
        case value
        when String, Integer
          value
        when Hash
          safe_arg_hash value
        when Array
          value.map { |x| safe_arg_value x }
        else
          value.to_s
        end
      end

      def safe_arg_hash(hsh)
        ::ActionDispatch::Http::ParameterFilter.new(WebServer.parameter_filters).filter hsh
      end
    end

    module SafeDependencies
      private

      def rails
        Object.const_defined?(:Rails) ? Object.const_get(:Rails) : nil
      end

      def sidekiq
        Object.const_defined?(:Sidekiq) ? Object.const_get(:Sidekiq) : nil
      end
    end
  end
end
