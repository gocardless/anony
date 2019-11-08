# frozen_string_literal: true

module Anony
  # This class curries the max_length into itself so it exists as a parameterless block
  # that can be called by Anony.
  #
  # @example Direct usage:
  #   anonymise do
  #     with_strategy(OverwriteHex.new(20), :field, :field)
  #   end
  #
  # @example Helper method, assumes length = 36
  #   anonymise do
  #     hex :field
  #   end
  #
  # @example Helper method with explicit length
  #   anonymise do
  #     hex :field, max_length: 20
  #   end
  OverwriteHex = Struct.new(:max_length) do
    def call(_existing_value)
      hex_length = max_length / 2 + 1
      SecureRandom.hex(hex_length)[0, max_length]
    end
  end
end
