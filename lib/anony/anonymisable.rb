# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/module"

require_relative "dsl"

module Anony
  module Anonymisable
    extend ActiveSupport::Concern

    ANONYMISED_AT = :anonymised_at

    class_methods do
      def anonymise(&block)
        anonymise_config.instance_eval(&block)
      end

      private def anonymise_config
        @anonymise_config ||= DSL.new
      end

      delegate :anonymisable_fields, :destroy_on_anonymise, to: :anonymise_config

      def valid_anonymisation?
        destroy_on_anonymise || unhandled_fields.empty?
      end

      def validate_anonymisation!
        raise FieldException, unhandled_fields unless valid_anonymisation?
      end

      private def unhandled_fields
        anonymisable_columns =
          column_names.map(&:to_sym).
            reject { |c| Config.ignore?(c) }.
            reject { |c| c == ANONYMISED_AT }

        handled_fields = anonymisable_fields.keys

        anonymisable_columns - handled_fields
      end
    end

    def anonymise!
      self.class.validate_anonymisation!

      return destroy! if self.class.destroy_on_anonymise

      anonymise_configured_fields

      if self.class.column_names.include?(ANONYMISED_AT.to_s)
        write_attribute(ANONYMISED_AT, Strategies::CurrentDatetime.call(nil))
      end

      save!
    end

    private def anonymise_configured_fields
      self.class.anonymisable_fields.each_key do |field|
        anonymise_field(field)
      end
    end

    private def anonymise_field(field)
      raise FieldException, field unless self.class.anonymisable_fields.key?(field)
      return unless self.class.column_names.include?(field.to_s)

      strategy = self.class.anonymisable_fields.fetch(field)
      current_value = read_attribute(field)

      write_attribute(field, anonymised_value(strategy, current_value))
    end

    private def anonymised_value(strategy, current_value)
      if strategy.is_a?(Proc)
        instance_exec(current_value, &strategy)
      elsif strategy.respond_to?(:call)
        strategy.call(current_value)
      else
        strategy
      end
    end
  end
end
