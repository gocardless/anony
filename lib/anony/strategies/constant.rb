# frozen_string_literal: true

module Anony
  module Strategies
    Constant = Struct.new(:value) do
      def call(_existing_value)
        value
      end
    end
  end
end
