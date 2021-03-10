# frozen_string_literal: true

begin
  require 'active_support/parameter_filter'
  FatherlyAdvice::SAFE_ARG_CLASS = ::ActiveSupport::ParameterFilter
rescue LoadError
  begin
      require 'action_dispatch/http/parameter_filter'
      FatherlyAdvice::SAFE_ARG_CLASS = ::ActionDispatch::Http::ParameterFilter
  rescue LoadError
    FatherlyAdvice::SAFE_ARG_CLASS = nil
    end
end

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
        raise 'missing safe argument class' unless FatherlyAdvice::SAFE_ARG_CLASS

        FatherlyAdvice::SAFE_ARG_CLASS.new(WebServer.parameter_filters).filter hsh
      end

      module_function

      def default_filters
        %i[
          account_name account_number acct_no address address_1 address_2 alt_phone api_access_token
          authorization_token card_number cell_phone city corrected_employer_phone cvv date_of_birth_day
          date_of_birth_month date_of_birth_year dba dl_number dob email employer_2_name employer_2_phone
          employer_name employer_phone encrypted_password encrypted_password_iv expiry first_name home_phone
          identification_number identity_card_number identity_number last_name legal_business_name
          mailing_address_1 mailing_address_2 main_phone mobile_phone name new_account_number
          new_routing_number password password_confirmation password_digest phone_number previous_address_1
          previous_address_2 reference_1_name reference_1_phone reference_2_name reference_2_phone
          reset_password_token routing_no routing_number secondary_phone_number secret ssn street_address
          token user user_token zip
        ]
      end
    end

    module SafeDependencies
      private

      def rails
        Object.const_defined?(:Rails) ? Object.const_get(:Rails) : nil
      end

      def rails?
        !!rails
      end

      def rails_init?
        rails && Object.const_defined?(:RAILS_INITIALIZED)
      end

      def sidekiq
        Object.const_defined?(:Sidekiq) ? Object.const_get(:Sidekiq) : nil
      end
    end
  end
end
