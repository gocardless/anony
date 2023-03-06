# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

require_relative "./strategies/destroy"
require_relative "./strategies/overwrite"
require_relative "./selectors"

module Anony
  class ModelConfig
    # @api private
    class UndefinedStrategy
      def valid?
        false
      end

      def validate!
        raise ArgumentError, "Must specify either :destroy or :overwrite strategy"
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
      @selectors_config = nil
      @skip_filter = nil
      instance_exec(&block) if block
    end

    # @api private
    # Applies the given strategy, taking into account any filters or conditions.
    #
    # @example
    #   Anony::ModelConfig.new(Manager).apply(Manager.new)
    def apply(instance)
      return Result.skipped if @skip_filter && instance.instance_exec(&@skip_filter)

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

    # Use the overwrite strategy to configure rules for individual fields. This method is
    # incompatible with the destroy strategy.
    #
    # This method takes a configuration block. All configuration is applied to
    # Anony::Strategies::Overwrite.
    #
    # @see Anony::Strategies::Overwrite
    #
    # @example
    #   anonymise do
    #     overwrite do
    #       hex :first_name
    #     end
    #   end
    def overwrite(&block)
      unless @strategy.is_a?(UndefinedStrategy)
        raise ArgumentError, "Cannot specify :overwrite when another strategy already defined"
      end

      @strategy = Strategies::Overwrite.new(@model_class, &block)
    end

    # Define selectors to select records that apply to a particular subject.
    # This method taks a configuration block that then builds Selectors
    #
    # @see Anony::Selectors
    #
    # @example
    #
    #   anonymise do
    #     selectors do
    #       for_subject(:user_id) { |user_id| self.select_for_user(user_id) }
    #     end
    #   end
    #
    #   ModelName.anonymise_for!(:user_id, "user_1234")
    def selectors(&block)
      @selectors_config = Selectors.new(@model_class, &block)
    end

    def select(subject, subject_id, &block)
      @selectors_config.select(subject, subject_id, &block)
    end

    def selector_for?(subject)
      return nil if @selectors_config.nil?

      @selectors_config.selectors[subject].present?
    end

    # Prevent any anonymisation strategy being applied when the provided block evaluates
    # to true. The block is executed in the model context.
    #
    # @example
    #   anonymise do
    #     skip_if { !persisted? }
    #   end
    def skip_if(&if_condition)
      raise ArgumentError, "Block required for :skip_if" unless if_condition

      @skip_filter = if_condition
    end
  end
end
