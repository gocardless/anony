# frozen_string_literal: true

module Anony
  module FieldLevelStrategies
    # Registers a new Anony strategy with a given name. Strategies are then available
    # inside the `anonymise` block.
    #
    # @param name [Symbol] The name of the strategy you'd like to use
    # @param klass_or_constant [Object] The object you'd like to statically return, or an
    #   object which responds to `#call(original)`.
    # @yield [original_value] The previous value of the field. The result of the block
    #   will be applied to that field. If a block is not given, klass_or_constant will be
    #   used as the strategy instead.
    #
    # @example Reversing a string
    #   Anony::FieldLevelStrategies.register(:reverse) { |value| value.reverse }
    #
    #   class Manager
    #     anonymise { reverse :first_name }
    #   end
    #
    # @example Using a named strategy class
    #   Anony::FieldLevelStrategies.register(:classify, Classifier)
    #
    #   class Manager
    #     anonymise { classify :resource_type }
    #   end
    #
    # @example Using a constant value
    #   Anony::FieldLevelStrategies.register(:nilable, nil)
    #
    #   class Manager
    #     anonymise { nilable :date_of_birth }
    #   end
    def self.register(name, klass_or_constant = nil, &block)
      if block_given?
        strategy = block
      elsif !klass_or_constant.nil?
        strategy = klass_or_constant
      else
        raise ArgumentError, "Must pass either a block, constant value or strategy class"
      end

      define_method(name) { |*fields| with_strategy(strategy, *fields) }

      @strategies[name] = strategy
    end

    # Helper method for retrieving the strategy block (or testing that it exists).
    #
    # @param name [Symbol] The name of the strategy to retrieve.
    # @raise [ArgumentError] If the strategy is not already registered
    def self.[](name)
      @strategies.fetch(name) do
        raise ArgumentError, "Unrecognised strategy `#{name.inspect}`"
      end
    end

    @strategies = {}
  end
end

require "securerandom"

Anony::FieldLevelStrategies.register(:email) do
  sprintf("%<random>s@example.com", random: SecureRandom.uuid)
end

Anony::FieldLevelStrategies.register(:phone_number, "+1 617 555 1294")

Anony::FieldLevelStrategies.register(:current_datetime) do |_original|
  current_time_from_proper_timezone
end

Anony::FieldLevelStrategies.register(:nilable) { nil }

Anony::FieldLevelStrategies.register(:no_op) { |value| value }

module Anony
  module Strategies
    # This class curries the max_length into itself so it exists as a parameterless block
    # that can be called by Anony.
    #
    # @example Direct usage:
    #   anonymise do
    #     fields do
    #       with_strategy(OverwriteHex.new(20), :field, :field)
    #     end
    #   end
    #
    # @example Helper method, assumes length = 36
    #   anonymise do
    #     fields do
    #       hex :field
    #     end
    #   end
    #
    # @example Helper method with explicit length
    #   anonymise do
    #     fields do
    #       hex :field, max_length: 20
    #     end
    #   end
    OverwriteHex = Struct.new(:max_length) do
      def call(_existing_value)
        hex_length = max_length / 2 + 1
        SecureRandom.hex(hex_length)[0, max_length]
      end
    end
  end
end
