# frozen_string_literal: true

module Anony
  # This exception is thrown if you define more than one strategy for the same field.
  #
  # @example
  #   anonymise do
  #     overwrite do
  #       ignore :first_name
  #       nilable :first_name
  #     end
  #   end
  class DuplicateStrategyException < StandardError
    def initialize(fields)
      fields = Array(fields)
      super("Duplicate anonymisation strategy for field(s) #{fields}")
    end
  end
end
