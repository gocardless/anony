# frozen_string_literal: true

module Anony
  module Strategies
    # The interface for configuring a destroy strategy. This strategy is not compatible
    # with Anony::Strategies::Fields.
    #
    # @example
    #   anonymise do
    #     destroy
    #   end
    class Destroy
      # This strategy takes no configuration so #valid? always returns true
      def valid?
        true
      end

      # This strategy takes no configuration so #validate! always returns true
      def validate!
        true
      end

      # Apply the Destroy strategy to the model instance. In this case, it calls
      # `#destroy!`.
      #
      # @param [ActiveRecord::Base] instance An instance of the model
      def apply(instance)
        instance.destroy!
      end
    end
  end
end
