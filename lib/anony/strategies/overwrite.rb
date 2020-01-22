# frozen_string_literal: true

require_relative "../field_level_strategies"

module Anony
  module Strategies
    # The interface for configuring a field-level strategy. All of the methods here are
    # made available inside the `overwrite { ... }` block:
    #
    # @example
    #   anonymise do
    #     overwrite do
    #       nilable :first_name
    #       email :email_address
    #       with_strategy(:last_name) { "last-#{id}" }
    #     end
    #   end
    class Overwrite
      include FieldLevelStrategies

      # @!visibility private
      def initialize(model_class, &block)
        @model_class = model_class
        @anonymisable_fields = {}
        instance_eval(&block) if block_given?
      end

      # A hash containing the fields and their anonymisation strategies.
      attr_reader :anonymisable_fields

      # Check whether the combination of field-level rules is valid
      def valid?
        validate!
        true
      rescue FieldException
        false
      end

      def validate!
        raise FieldException, unhandled_fields if unhandled_fields.any?
      end

      # Apply the Overwrite strategy on the model instance, which applies each of the
      # configured transformations and updates the :anonymised_at field if it exists.
      #
      # @param [ActiveRecord::Base] instance An instance of the model
      def apply(instance)
        if !@anonymisable_fields.key?(:anonymised_at) &&
            @model_class.column_names.include?("anonymised_at")
          current_datetime(:anonymised_at)
        end

        result_fields = {}

        @anonymisable_fields.each_key do |field|
          result_fields[field.to_sym] = anonymise_field(instance, field)
        end

        instance.save!

        Result.overwritten(result_fields)
      end

      # Configure a custom strategy for one or more fields. If a block is given that is used
      # as the strategy, otherwise the first argument is used as the strategy.
      #
      # @param [Proc, Object] strategy Any object which responds to
      #   `.call(previous_value)`. Not used if a block is provided.
      # @param [Array<Symbol>] fields A list of one or more fields to apply this strategy to.
      # @param [Block] &block A block to use as the strategy.
      # @yieldparam previous [Object] The previous value of the field
      # @yieldreturn [Object] The value to set on that field.
      # @raise [ArgumentError] If the combination of strategy, fields and block is invalid.
      # @raise [DuplicateStrategyException] If more than one strategy is defined for the same field.
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

        guard_duplicate_strategies!(fields)

        fields.each { |field| @anonymisable_fields[field] = strategy }
      end

      # Helper method to use the :hex strategy
      # @param [Array<Symbol>] fields A list of one or more fields to apply this strategy to.
      # @see Strategies::OverwriteHex
      #
      # @example
      #   hex :first_name
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
      #   ignore :external_system_id, :externalised_at
      def ignore(*fields)
        already_ignored = fields.select { |field| Config.ignore?(field) }

        if already_ignored.any?
          raise ArgumentError, "Cannot ignore #{already_ignored.inspect} " \
                              "(fields already ignored in Anony::Config)"
        end

        no_op(*fields)
      end

      private def unhandled_fields
        anonymisable_columns =
          @model_class.column_names.map(&:to_sym).
            reject { |c| Config.ignore?(c) }.
            reject { |c| c == :anonymised_at }

        handled_fields = @anonymisable_fields.keys

        anonymisable_columns - handled_fields
      end

      private def anonymise_field(instance, field)
        return unless @model_class.column_names.include?(field.to_s)

        strategy = @anonymisable_fields.fetch(field)
        current_value = instance.read_attribute(field)

        instance.write_attribute(field, anonymised_value(instance, strategy, current_value))
      end

      private def anonymised_value(instance, strategy, current_value)
        if strategy.is_a?(Proc)
          instance.instance_exec(current_value, &strategy)
        elsif strategy.respond_to?(:call)
          strategy.call(current_value)
        else
          strategy
        end
      end

      private def guard_duplicate_strategies!(fields)
        defined_fields = @anonymisable_fields.keys
        duplicate_fields = defined_fields & fields

        raise DuplicateStrategyException, duplicate_fields if duplicate_fields.any?
      end
    end
  end
end
