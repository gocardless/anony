# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "./strategies/fields"
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
      # @see DSL Anony::Strategies::Fields - the methods available inside this block
      # @example
      #   class Manager < ApplicationRecord
      #     anonymise do
      #       fields do
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
    # @return [true] if the save was successful
    # @raise [FieldException] if the configuration is invalid (configuration is lazily validated)
    # @raise [ActiveRecord::RecordNotSaved] if the save failed (e.g. a validation error)
    # @raise [ActiveRecord::RecordNotDestroyed] if the destroy failed (where this strategy
    #   has been configured)
    # @example
    #   manager = Manager.first
    #   manager.anonymise!
    def anonymise!
      raise ArgumentError, ".anonymise not yet invoked" unless self.class.anonymise_config

      self.class.anonymise_config.validate!
      self.class.anonymise_config.apply(self)
    end

    # @!visibility private
    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
