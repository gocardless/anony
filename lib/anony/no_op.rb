# frozen_string_literal: true

module Anony
  module NoOp
    def self.call(value, *_)
      value
    end
  end
end
