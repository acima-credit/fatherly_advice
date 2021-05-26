# frozen_string_literal: true

module FatherlyAdvice
  module DbConfig
    class DefaultNotConfigured < StandardError
      def initialize(name)
        super "default value not configured for #{name}"
      end
    end

    module ModelMixin
      def default_by_name(name, unset_default = nil)
        found = get name
        return found.value.to_s if found

        raise DefaultNotConfigured, name if unset_default.nil?

        make name, unset_default
      end

      def update_by_name(name, value, found = nil)
        found ||= get name

        return set(found, value) if found

        make name, value
      end

      def add_array_entry_by_name(name, value)
        found = get name
        if found
          new_value = found.value.to_s.split(',').push(value).join(',')
          set found, new_value
        else
          make name, value
        end
        value
      end

      def default_array_by_name(name, *unset_default)
        unset_default_ary = unset_default.flatten.map(&:to_s).join(',')
        default_by_name(name, unset_default_ary).split(',')
      end

      def cached_by_name(name, unset_default = nil)
        cache.fetch(name.to_s) do
          default_by_name(name, unset_default)
        end
      end

      def remove(name)
        get(name)&.destroy
        cache.delete name.to_s
      end

      def cache
        DbConfig.cache
      end

      private

      def get(name)
        find_by name: name.to_s
      end

      def set(instance, value)
        instance.update value: value.to_s
        cache.write name.to_s, value.to_s
        instance.value
      end

      def make(name, value)
        create(name: name.to_s, value: value.to_s).tap do
          cache.write name.to_s, value.to_s
        end&.value
      end
    end

    module_function

    extend ModelMixin

    def model(value = :none)
      unless value == :none
        unless value.nil?
          value.send :extend, ModelMixin
          value.const_set :DefaultNotConfigured, FatherlyAdvice::DbConfig::DefaultNotConfigured
        end
        @model = value
      end
      @model
    end

    def cache_options
      {
        expires_in: 1.minute
      }
    end

    def cache_class(value = :none)
      @cache_class = value unless value == :none
      @cache_class || ActiveSupport::Cache::MemoryStore
    end

    def cache
      @cache ||= cache_class.new cache_options
    end

    def method_missing(method_name, *arguments, &block)
      return super if model.nil?

      super unless model.respond_to?(method_name)

      model.send(method_name, *arguments, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      return super if model.nil?

      model.respond_to?(method_name)
    end
  end
end
