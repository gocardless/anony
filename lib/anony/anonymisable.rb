# frozen_string_literal: true

require "active_support/concern"

module Anony
  class AnonymisableConfig
    def with_strategy(field, strategy = nil, opts: {}, &block)
      if block_given?
        strategy = block
      else
        raise StrategyException, strategy unless strategy.respond_to?(:call)
      end

      anonymisable_fields[field] = { strategy: strategy, opts: opts }
    end

    def hex(field, opts: {})
      with_strategy(field, OverwriteHex, opts: opts)
    end

    def email(field)
      with_strategy(field, AnonymisedEmail)
    end

    def nilable(field)
      with_strategy(field, Nilable)
    end

    def anonymisable_fields
      @anonymisable_fields ||= {}
    end

    def ignore(*fields)
      fields.each do |field|
        if Config.ignore?(field)
          raise ArgumentError,
                "Trying to ignore `#{field}` which is already ignored in Anony::Config"
        end

        with_strategy(field, NoOp)
      end
    end
  end

  module Anonymisable
    extend ActiveSupport::Concern

    class_methods do
      def anonymise(&block)
        anonymiser = AnonymisableConfig.new
        anonymiser.instance_eval(&block)
        @anonymisable_fields = anonymiser.anonymisable_fields
      end

      def anonymisable_fields
        @anonymisable_fields
      end
    end

    def anonymise_field(field)
      raise FieldException, field unless self.class.anonymisable_fields.key?(field)

      config = self.class.anonymisable_fields[field]
      current_value = read_attribute(field)
      anonymised_value = config.fetch(:strategy).
        call(current_value, opts: config.fetch(:opts))

      write_attribute(field, anonymised_value)
    end

    def anonymise
      raise FieldException, unhandled_fields unless valid_anonymisation?

      self.class.anonymisable_fields.each do |field, _|
        anonymise_field(field)
      end

      self
    end

    #  VALIDATION.
    def valid_anonymisation?
      unhandled_fields.empty?
    end

    private def unhandled_fields
      anonymisable_columns =
        self.class.column_names.map(&:to_sym).reject { |c| Config.ignore?(c) }
      handled_fields = self.class.anonymisable_fields.map { |k, _| k }

      anonymisable_columns - handled_fields
    end
  end
end
