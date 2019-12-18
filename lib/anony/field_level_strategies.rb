# frozen_string_literal: true

require "securerandom"

module Anony
  # This class is a singleton, containing all of the known strategies that Anony can use
  # to anonymise individual fields in your models.
  module FieldLevelStrategies
    # Registers a new Anony strategy (or overwrites an existing strategy) of a given name.
    # Strategies are then available everywhere inside the `anonymise` block.
    #
    # @param name [Symbol] The name of the strategy you'd like to use
    # @param klass_or_constant [Object] The object you'd like to statically return, or an
    #   object which responds to `#call(original_value)`.
    # @yield [original_value] The previous value of the field. The result of the block
    #   will be applied to that field. If a block is not given, klass_or_constant will be
    #   used as the strategy instead.
    # @raise [ArgumentError] If using neither a block nor strategy class
    #
    # @example Reversing a string using a block
    #   Anony::FieldLevelStrategies.register(:reverse) do |original_value|
    #     original_value.reverse
    #   end
    #
    #   class Manager
    #     anonymise { reverse :first_name }
    #   end
    #
    # @example Using a named strategy class
    #   class Classifier
    #     def self.call(original_value)
    #       "Classy version of #{original_value}"
    #     end
    #   end
    #
    #   Anony::FieldLevelStrategies.register(:classify, Classifier)
    #
    #   class Manager
    #     anonymise { classify :resource_type }
    #   end
    #
    # @example Using a constant value
    #   Anony::FieldLevelStrategies.register(:forty_two, 42)
    #
    #   class Manager
    #     anonymise { forty_two :date_of_birth }
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

    # @!method email(field)
    #   Overwrite a field with a randomised email, where the user part is generated with
    #   `SecureRandom.uuid` and the domain is "example.com".
    #
    #   For example, this might generate an email like:
    #   `"86b5b19d-2224-4c3d-bead-e9d4a1934303@example.com"`
    #
    #   @example Overwriting the field called :email_address
    #     email :email_address
    register(:email) do
      sprintf("%<random>s@example.com", random: SecureRandom.uuid)
    end

    # @!method phone_number(field)
    #   Overwrite a field with a static phone number. Currently this is "+1 617 555 1294"
    #   but you would probably want to override this for your use case.
    #
    #   @example Overwriting the field called :phone
    #     phone_number :phone
    #
    #   @example Using a different phone number
    #     Anony::FieldLevelStrategies.register(:phone_number, "+44 07700 000 000")
    register(:phone_number, "+1 617 555 1294")

    # @!method current_datetime(field)
    #   Overwrite a field with the current datetime. This is provided by
    #   `current_time_from_proper_timezone`, an internal method exposed from
    #   ActiveRecord::Timestamp.
    #
    #   @example Overwriting the field called :signed_up_at
    #     current_datetime :signed_up_at
    register(:current_datetime) { |_original| current_time_from_proper_timezone }

    # @!method nilable(field)
    #   Overwrite a field with the value `nil`.
    #
    #   @example Overwriting the field called :optional_field
    #     nilable :optional_field
    register(:nilable) { nil }

    # @!method noop(field)
    #   This strategy applies no transformation rules at all. It is used internally by the
    #   ignore strategy so you should probably use that instead.
    #
    #   @see Anony::Strategies::Fields#ignore
    register(:no_op) { |value| value }
  end
end

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
