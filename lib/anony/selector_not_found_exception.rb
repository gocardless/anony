# frozen_string_literal: true

module Anony
  class SelectorNotFoundException < StandardError
    def initialize(selector, model_name)
      super("Selector for #{selector} not found. Make sure you have one defined in #{model_name}")
    end
  end
end
