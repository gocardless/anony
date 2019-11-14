# frozen_string_literal: true

module Anony
  module Strategies
    module NoOp
      def self.call(value)
        value
      end
    end
  end
end
