# frozen_string_literal: true

module Anony
  class StrategyException < StandardError
    def initialize(strategy)
      super("Invalid anonymisation strategy #{strategy.class}")
    end
  end
end
