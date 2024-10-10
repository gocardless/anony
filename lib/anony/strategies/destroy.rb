# frozen_string_literal: true

module Anony
  module Strategies
    # The interface for configuring a destroy strategy. This strategy is not compatible
    # with Anony::Strategies::Overwrite.
    #
    # @example
    #   anonymise do
    #     destroy
    #   end
    class Destroy
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

      # Apply the Destroy strategy to the model instance. In this case, it calls
      # `#destroy!`.
      #
      # @param [ActiveRecord::Base] instance An instance of the model
      def apply(instance)
        instance.destroy!
        Result.destroyed(instance)
      end
    end
  end
end
