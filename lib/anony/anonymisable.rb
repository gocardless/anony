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

      fields = fields.flatten

      raise ArgumentError, "Block or Strategy object required" unless strategy
      raise ArgumentError, "One or more fields required" unless fields.any?
      raise ArgumentError, "Can't specify destroy and strategies for fields" if destroy_on_anonymise

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

    private

    def method_missing(method_name, *fields)
      raise NoMethodError unless respond_to_missing?(method_name)

      with_strategy(*fields, &Anony::Config.strategy(method_name))
    end

    def respond_to_missing?(method_name)
      Anony::Config.strategy(method_name) != nil
    end
  end

  module Anonymisable
    extend ActiveSupport::Concern

    ANONYMISED_AT = :anonymised_at

    class_methods do
      def anonymise(&block)
        anonymiser.instance_eval(&block)
      end

      def anonymiser
        @anonymiser ||= AnonymisableConfig.new
      end

      delegate :anonymisable_fields, :destroy_on_anonymise, to: :anonymiser
    end

    def anonymise!
      raise FieldException, unhandled_fields unless valid_anonymisation?

      return destroy! if self.class.destroy_on_anonymise

      anonymise_configured_fields

      if self.class.column_names.include?(ANONYMISED_AT.to_s)
        write_attribute(ANONYMISED_AT, Strategies::CurrentDatetime.call(nil))
      end

      save!
    end

    #  VALIDATION.
    def valid_anonymisation?
      self.class.destroy_on_anonymise || unhandled_fields.empty?
    end

    private def anonymise_configured_fields
      self.class.anonymisable_fields.each_key do |field|
        anonymise_field(field)
      end
    end

    private def unhandled_fields
      anonymisable_columns =
        self.class.column_names.map(&:to_sym).
          reject { |c| Config.ignore?(c) }.
          reject { |c| c == ANONYMISED_AT }

      handled_fields = self.class.anonymisable_fields.keys

      anonymisable_columns - handled_fields
    end

    private def anonymise_field(field)
      raise FieldException, field unless self.class.anonymisable_fields.key?(field)

      strategy = self.class.anonymisable_fields.fetch(field)
      current_value = read_attribute(field)

      anonymised_value = if strategy.is_a?(Proc)
                           instance_exec(current_value, &strategy)
                         else
                           strategy.call(current_value)
                         end

      write_attribute(field, anonymised_value)
    end
  end
end
