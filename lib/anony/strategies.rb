# frozen_string_literal: true

module Anony
  module Strategies
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
    #   Anony::Strategies.register(:reverse) { |value| value.reverse }
    #
    #   class Manager
    #     anonymise { reverse :first_name }
    #   end
    #
    # @example Using a named strategy class
    #   Anony::Strategies.register(:classify, Classifier)
    #
    #   class Manager
    #     anonymise { classify :resource_type }
    #   end
    #
    # @example Using a constant value
    #   Anony::Strategies.register(:nilable, nil)
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
