# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "./strategies/overwrite"
require_relative "model_config"
require_relative "anonymisable_models"
require_relative "anonymisation_not_known_exception"

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

      attr_reader :anonymise_config
    end

    # Run all anonymisation strategies on the model instance before saving it.
    #
    # @return [Anony::Result] described if the save was successful, and the fields or errors created
    # @example
    #   manager = Manager.first
    #   manager.anonymise!
    def anonymise!(ignore_anonymisation_date: false)
      unless self.class.anonymise_config
        raise ArgumentError, "#{self.class.name} does not have an Anony configuration"
      end

      return Result.skipped unless should_anonymise?(ignore_anonymisation_date)

      self.class.anonymise_config.validate!
      self.class.anonymise_config.apply(self)
    rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotDestroyed => e
      Result.failed(e)
    end

    def anonymised?
      raise AnonymisationNotKnownException unless respond_to?(:anonymised_at)
      anonymised_at.present?
    end

    private def should_anonymise?(ignore_anonymisation_date)
      return true if ignore_anonymisation_date || !respond_to?(:anonymise_after)

      anonymise_after.nil? || !anonymise_after.future?
    end

    # @!visibility private
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        scope :exposed, -> { where(anonymised_at: nil) }
        scope :anonymised, -> { where.not(anonymised_at: nil) }
        scope :due_for_anonymisation, -> { where('anonymise_after < CURRENT_DATE').exposed }
      end

      AnonymisableModels.add(base)
    end
  end
end
