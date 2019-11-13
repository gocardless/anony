# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/module"

module Anony
  class AnonymisableConfig
    def initialize
      @anonymisable_fields = {}
      @destroy_on_anonymise = false
    end

    attr_reader :anonymisable_fields, :destroy_on_anonymise

    def with_strategy(strategy, *fields, &block)
      unless strategy.respond_to?(:call)
        fields.unshift(strategy)
        strategy = block
      end

      raise ArgumentError, "Block or Strategy object required" unless strategy
      raise ArgumentError, "One or more fields required" unless fields.any?

      if destroy_on_anonymise
        raise ArgumentError, "Can't specify destroy and strategies for fields"
      end

      fields.each { |field| anonymisable_fields[field] = strategy }
    end

    def hex(*fields, max_length: 36)
      with_strategy(Strategies::OverwriteHex.new(max_length), *fields)
    end

    def email(*fields)
      with_strategy(Strategies::AnonymisedEmail, *fields)
    end

    def phone_number(*fields)
      with_strategy(Strategies::AnonymisedPhoneNumber, *fields)
    end

    def nilable(*fields)
      with_strategy(Strategies::Nilable, *fields)
    end

    def current_datetime(*fields)
      with_strategy(Strategies::CurrentDatetime, *fields)
    end

    def ignore(*fields)
      already_ignored = fields.select { |field| Config.ignore?(field) }

      if already_ignored.any?
        raise ArgumentError, "Cannot ignore #{already_ignored.inspect} " \
                             "(fields already ignored in Anony::Config)"
      end

      with_strategy(Strategies::NoOp, *fields)
    end

    def destroy
      unless anonymisable_fields.empty?
        raise ArgumentError, "Can't specify destroy and strategies for fields"
      end

      @destroy_on_anonymise = true
    end
  end

  module Anonymisable
    extend ActiveSupport::Concern

    class_methods do
      def anonymise(&block)
        # Automatically update :anonymised_at column if it exists (can be overridden)
        if column_names.include?("anonymised_at")
          anonymiser.current_datetime(:anonymised_at)
        end

        anonymiser.instance_eval(&block)
      end

      def anonymiser
        @anonymiser ||= AnonymisableConfig.new
      end

      delegate :anonymisable_fields, :destroy_on_anonymise, to: :anonymiser
    end

    def anonymise!
      raise FieldException, unhandled_fields unless valid_anonymisation?

      if self.class.destroy_on_anonymise
        destroy!
      else
        self.class.anonymisable_fields.each do |field, _|
          anonymise_field(field)
        end

        save!
      end
    end

    #  VALIDATION.
    def valid_anonymisation?
      self.class.destroy_on_anonymise || unhandled_fields.empty?
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
