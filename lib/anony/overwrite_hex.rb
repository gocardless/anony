# frozen_string_literal: true

module Anony
  module OverwriteHex
    def self.call(_, opts: { max_length: 36 })
      max_length = opts[:max_length]
      hex_length = max_length / 2 + 1
      SecureRandom.hex(hex_length).first(max_length)
    end
  end
end
