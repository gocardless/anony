# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "dsl"

module Anony
  # The main Anony object to include in your ActiveRecord class.
  #
  # @example Using in a single model
  #   class Manager < ApplicationRecord
  #     include Anony::Anonymisable
  #   end
  #
  # @example Making this available to your whole application
  #   class ApplicationRecord < ActiveRecord::Base
  #     include Anony::Anonymisable
  #   end
  module Anonymisable
    ANONYMISED_AT = :anonymised_at
    private_constant :ANONYMISED_AT

    # Mixin containing methods that will be exposed on the ActiveRecord class after
    # including the Anonymisable module.
    #
    # The primary method, #anonymise, is used to configure the strategies to apply. This
    # configuration is lazily executed when trying to actually anonymise an instance:
    # this is because the database or other lazily-loaded properties are not necessarily
    # available when the class is configured.
    module ClassMethods
      # Define a set of anonymisation configuration on the ActiveRecord class.
      #
      # @yield A configuration block
      # @see DSL Anony::DSL - the methods available inside this block
      # @example
      #   class Manager < ApplicationRecord
      #     anonymise do
      #       with_strategy(:first_name) { "ANONYMISED" }
      #     end
      #   end
      def anonymise(&block)
        anonymise_config.instance_eval(&block)
      end

      # Check whether the model has been configured correctly. Returns a simple true/false.
      #
      # @return [Boolean]
      # @example
      #   Manager.valid_anonymisation?
      def valid_anonymisation?
        destroy_on_anonymise || unhandled_fields.empty?
      end

      # Validates the configuration and raises an exception if it is invalid.
      # @raise [FieldException]
      # @return [nil]
      # @example
      #   Manager.validate_anonymisation!
      def validate_anonymisation!
        raise FieldException, unhandled_fields unless valid_anonymisation?
      end

      private def anonymise_config
        @anonymise_config ||= DSL.new
      end

      delegate :anonymisable_fields, :destroy_on_anonymise, to: :anonymise_config

      private def unhandled_fields
        anonymisable_columns =
          column_names.map(&:to_sym).
            reject { |c| Config.ignore?(c) }.
            reject { |c| c == ANONYMISED_AT }

        handled_fields = anonymisable_fields.keys

        anonymisable_columns - handled_fields
      end
    end

    # Run all anonymisation strategies on the model instance before saving it.
    #
    # @return [true] if the save was successful
    # @raise [FieldException] if the configuration is invalid (configuration is lazily validated)
    # @raise [ActiveRecord::RecordNotSaved] if the save failed (e.g. a validation error)
    # @raise [ActiveRecord::RecordNotDestroyed] if the destroy failed (where this strategy
    #   has been configured)
    # @example
    #   manager = Manager.first
    #   manager.anonymise!
    def anonymise!
      self.class.validate_anonymisation!

      return destroy! if self.class.destroy_on_anonymise

      anonymise_configured_fields

      if self.class.column_names.include?(ANONYMISED_AT.to_s)
        write_attribute(ANONYMISED_AT, current_time_from_proper_timezone)
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

    # @!visibility private
    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
