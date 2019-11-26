# frozen_string_literal: true

module Anony
  class OverwrittenStrategyException < StandardError
    def initialize(fields)
      fields = Array(fields)
      super("Overwritten anonymisation strategy for field(s) #{fields}")
    end
  end
end
