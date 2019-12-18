# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "./strategies/destroy"
require_relative "./strategies/fields"

module Anony
  class ModelConfig
    # @api private
    class UndefinedStrategy
      def valid?
        false
      end

      def validate!
        raise ArgumentError, "Must specify either :destroy or :fields strategy"
      end
    end

    # @api private
    # Constructs a new instance of ModelConfig.
    #
    # @param [ActiveRecord::Base] model_class The model class the config is attached to.
    # @yield [block] For configuration of the ModelConfig instance.
    #
    # @example
    #   Anony::ModelConfig.new(Manager) { destroy }
    def initialize(model_class, &block)
      @model_class = model_class
      @strategy = UndefinedStrategy.new
      @skip_filter = nil
      instance_exec(&block) if block_given?
    end

    # @api private
    # Applies the given strategy, taking into account any filters or conditions.
    #
    # @example
    #   Anony::ModelConfig.new(Manager).apply(Manager.new)
    def apply(instance)
      raise Anony::SkippedException if @skip_filter && instance.instance_exec(&@skip_filter)

      @strategy.apply(instance)
    end

    delegate :valid?, :validate!, to: :@strategy

    # Use the deletion strategy instead of anonymising individual fields. This method is
    # incompatible with the fields strategy.
    #
    # This method takes no arguments or blocks.
    #
    # @example
    #   anonymise do
    #     destroy
    #   end
    def destroy
      raise ArgumentError, ":destroy takes no block" if block_given?
      unless @strategy.is_a?(UndefinedStrategy)
        raise ArgumentError, "Cannot specify :destroy when another strategy already defined"
      end

      @strategy = Strategies::Destroy.new
    end

    # Use the fields strategy to configure rules for individual fields. This method is
    # incompatible with the destroy strategy.
    #
    # This method takes a configuration block. All configuration is applied to
    # Anony::Strategies::Fields.
    #
    # @see Anony::Strategies::Fields
    #
    # @example
    #   anonymise do
    #     fields do
    #       hex :first_name
    #     end
    #   end
    def fields(&block)
      unless @strategy.is_a?(UndefinedStrategy)
        raise ArgumentError, "Cannot specify :fields when another strategy already defined"
      end

      @strategy = Strategies::Fields.new(@model_class, &block)
    end

    # Prevent any anonymisation strategy being applied when the provided block evaluates
    # to true. The block is executed in the model context.
    #
    # @example
    #   anonymise do
    #     skip_if { !persisted? }
    #   end
    def skip_if(&if_condition)
      raise ArgumentError, "Block required for :skip_if" unless block_given?

      @skip_filter = if_condition
    end
  end
end
