# frozen_string_literal: true

require_relative "strategies"

module Anony
  # The interface for configuring strategies. All of the methods here are made available
  # inside the `anonymise { ... }` block:
  #
  # @example
  #   anonymise do
  #     nilable :first_name
  #     email :email_address
  #     with_strategy(:last_name) { "last-#{id}" }
  #   end
  class DSL
    include Strategies

    # @!visibility private
    def initialize
      @anonymisable_fields = {}
      @destroy_on_anonymise = false
    end

    # @!visibility private
    attr_reader :anonymisable_fields, :destroy_on_anonymise

    # Configure a custom strategy for one or more fields. If a block is given that is used
    # as the strategy, otherwise the first argument is used as the strategy.
    #
    # @param [Proc, Object] strategy Any object which responds to `.call(previous_value)`. Not used
    #   if a block is provided.
    # @param [Array<Symbol>] fields A list of one or more fields to apply this strategy to.
    # @param [Block] &block A block to use as the strategy.
    # @yieldparam previous [Object] The previous value of the field
    # @yieldreturn [Object] The value to set on that field.
    # @raise [ArgumentError] If the combination of strategy, fields and block is invalid.
    #
    # @example With a named class
    #   class Reverse
    #     def self.call(previous)
    #       previous.reverse
    #     end
    #   end
    #
    #   with_strategy(Reverse, :first_name)
    #
    # @example With a constant value
    #   with_strategy({}, :metadata)
    #
    # @example With a block
    #   with_strategy(:first_name, :last_name) { |previous| previous.reverse }
    def with_strategy(strategy, *fields, &block)
      if block_given?
        fields.unshift(strategy)
        strategy = block
      end

      fields = fields.flatten

      raise ArgumentError, "Block or Strategy object required" unless strategy
      raise ArgumentError, "One or more fields required" unless fields.any?
      raise ArgumentError, "Can't specify destroy and strategies for fields" if destroy_on_anonymise

      fields.each { |field| anonymisable_fields[field] = strategy }
    end

    # Helper method to use the :hex strategy
    # @param [Array<Symbol>] fields A list of one or more fields to apply this strategy to.
    # @see Strategies::OverwriteHex
    def hex(*fields, max_length: 36)
      with_strategy(Strategies::OverwriteHex.new(max_length), *fields)
    end

    # Configure a list of fields that you don't want to anonymise.
    #
    # @param [Array<Symbol>] fields The fields to ignore
    # @raise [ArgumentError] If trying to ignore a field which is already globally
    #   ignored in Anony::Config.ignores
    #
    # @example
    #   anonymise do
    #     ignore :external_system_id, :externalised_at
    #   end
    def ignore(*fields)
      already_ignored = fields.select { |field| Config.ignore?(field) }

      if already_ignored.any?
        raise ArgumentError, "Cannot ignore #{already_ignored.inspect} " \
                             "(fields already ignored in Anony::Config)"
      end

      with_strategy(Strategies::NoOp, *fields)
    end

    # Use the deletion strategy instead of anonymising individual fields. This method is
    # incompatible with the other methods in this file.
    #
    # @raise [ArgumentError] If other strategies are used in the same class
    #
    # @example
    #   anonymise do
    #     destroy
    #   end
    def destroy
      unless anonymisable_fields.empty?
        raise ArgumentError, "Can't specify destroy and strategies for fields"
      end

      @destroy_on_anonymise = true
    end
  end
end
