# frozen_string_literal: true

module Anony
  # This exception is thrown if you try to overwrite the strategy for a field which is
  # already defined.
  #
  # @example
  #   anonymise do
  #     overwrite do
  #       ignore :first_name
  #       nilable :first_name
  #     end
  #   end
  class OverwrittenStrategyException < StandardError
    def initialize(fields)
      fields = Array(fields)
      super("Overwritten anonymisation strategy for field(s) #{fields}")
    end
  end
end
