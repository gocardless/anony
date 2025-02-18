# frozen_string_literal: true

module Anony
  module Strategies
    # The interface for configuring an ignore strategy. This strategy is not compatible
    # with the following strategies:
    # * Anony::Strategies::Destroy
    # * Anony::Strategies::Overwrite
    #
    # @example
    #   anonymise do
    #     ignore
    #   end
    class Ignore
      # Whether the strategy is valid. This strategy takes no configuration, so #valid?
      # always returns true
      #
      # @return [true]
      def valid?
        true
      end

      # Whether the strategy is valid, raising an exception if not. This strategy takes no
      # configuration, so #validate! always returns true
      #
      # @return [true]
      def validate!
        true
      end

      # Apply the Ignore strategy to the model instance. In this case, it is a noop
      #
      # @param [ActiveRecord::Base] instance An instance of the model
      def apply(instance)
        Result.skipped(instance)
      end
    end
  end
end
