# frozen_string_literal: true

module FatherlyAdvice
  module SidekiqHelpers
    module SafeSetter
      private

      def set(value, type, default = nil)
        return default unless value.present?

        case type
        when :string
          value.to_s
        when :integer
          value.to_i
        when :string_array
          value.map(&:to_s)
        when :time
          Time.zone.at value
        when :boolean
          value.to_s == 'true'
        end
      end
    end
  end
end
