# frozen_string_literal: true

module Anony
  class FieldException < StandardError
    def initialize(fields)
      fields = Array(fields)
      super("Invalid anonymisation strategy for field(s) #{fields}")
    end
  end
end
