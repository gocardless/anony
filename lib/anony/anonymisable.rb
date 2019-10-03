# frozen_string_literal: true

require "active_support/concern"

module Anony
  class AnonymisableConfig
    def with_strategy(strategy, *fields, &block)
      unless strategy.respond_to?(:call)
        fields.unshift(strategy)
        strategy = block
      end

      raise ArgumentError, "Block or Strategy object required" unless strategy
      raise ArgumentError, "One or more fields required" unless fields.any?

      fields.each { |field| anonymisable_fields[field] = strategy }
    end

    def hex(*fields, max_length: 36)
      with_strategy(OverwriteHex.new(max_length), *fields)
    end

    def email(*fields)
      with_strategy(AnonymisedEmail, *fields)
    end

    def nilable(*fields)
      with_strategy(Nilable, *fields)
    end

    def anonymisable_fields
      @anonymisable_fields ||= {}
    end

    def ignore(*fields)
      already_ignored = fields.select { |field| Config.ignore?(field) }

      if already_ignored.any?
        raise ArgumentError, "Cannot ignore #{already_ignored.inspect} " \
                             "(fields already ignored in Anony::Config)"
      end

      with_strategy(NoOp, *fields)
    end
  end

  module Anonymisable
    extend ActiveSupport::Concern

    class_methods do
      attr_reader :anonymisable_fields

      def anonymise(&block)
        anonymiser = AnonymisableConfig.new
        anonymiser.instance_eval(&block)
        @anonymisable_fields = anonymiser.anonymisable_fields
      end
    end

    included do
      @anonymisable_fields = {}
    end

    def anonymise!
      raise FieldException, unhandled_fields unless valid_anonymisation?

      self.class.anonymisable_fields.each do |field, _|
        anonymise_field(field)
      end

      save!
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

    private def anonymise_field(field)
      raise FieldException, field unless self.class.anonymisable_fields.key?(field)

      strategy = self.class.anonymisable_fields.fetch(field)
      current_value = read_attribute(field)
      anonymised_value = strategy.call(current_value)

      write_attribute(field, anonymised_value)
    end
  end
end
