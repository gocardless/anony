# frozen_string_literal: true

module Anony
  module Strategies
    module Nilable
      def self.call(_value)
        nil
      end
    end
  end
end
