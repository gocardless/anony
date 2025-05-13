# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "not_anonymisable_exception"
require_relative "strategies/overwrite"
require_relative "model_config"

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
    # Mixin containing methods that will be exposed on the ActiveRecord class after
    # including the Anonymisable module.
    #
    # The primary method, .anonymise, is used to configure the strategies to apply. This
    # configuration is lazily executed when trying to actually anonymise an instance:
    # this is because the database or other lazily-loaded properties are not necessarily
    # available when the class is configured.
    module ClassMethods
      # Define a set of anonymisation configuration on the ActiveRecord class.
      #
      # @yield A configuration block
      # @see DSL Anony::Strategies::Overwrite - the methods available inside this block
      # @example
      #   class Manager < ApplicationRecord
      #     anonymise do
      #       overwrite do
      #         with_strategy(:first_name) { "ANONYMISED" }
      #       end
      #     end
      #   end
      def anonymise(&block)
        @anonymise_config = ModelConfig.new(self, &block)
      end

      # Check whether the model has been configured correctly. Returns a simple
      # `true`/`false`. If configuration has not yet been configured, it returns `false`.
      #
      # @return [Boolean]
      # @example
      #   Manager.valid_anonymisation?
      def valid_anonymisation?
        return false unless @anonymise_config

        @anonymise_config.valid?
      end

      # Finds the records that relate to a particular subject and runs anonymise on
      # each of them. If a selector is not defined it will raise an exception.
      def anonymise_for!(subject, subject_id)
        unless anonymise_config
          raise ArgumentError, "#{name} does not have an Anony configuration"
        end

        records = anonymise_config.
          select(subject, subject_id)
        records.map do |record|
          if !record.respond_to?(:anonymise!)
            raise NotAnonymisableException, record
          end

          record.anonymise!
        end
      end

      # Checks if a selector has been defined for a given subject.
      # This is useful for when writing tests to check all models have a valid selector
      # for a given subject.
      # @return [Boolean]
      # @example
      #   Manager.selector_for?(:user_id)
      def selector_for?(subject)
        return false if anonymise_config.nil?

        anonymise_config.selector_for?(subject)
      end

      attr_reader :anonymise_config
    end

    # Run all anonymisation strategies on the model instance before saving it.
    #
    # @return [Anony::Result] described if the save was successful, and the fields or errors created
    # @example
    #   manager = Manager.first
    #   manager.anonymise!
    def anonymise!
      unless self.class.anonymise_config
        raise ArgumentError, "#{self.class.name} does not have an Anony configuration"
      end

      self.class.anonymise_config.validate! if Config.validate_before_anonymisation
      self.class.anonymise_config.apply(self)
    rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotDestroyed => e
      Result.failed(e, self)
    end

    def anonymised?
      anonymised_at.present?
    end

    # @!visibility private
    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
