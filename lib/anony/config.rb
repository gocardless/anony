# frozen_string_literal: true

module Anony
  module Config
    def self.ignore?(field)
      # In this case, we want to support literal matches, regular expressions and blocks,
      # all of which are helpfully handled by Object#===.
      #
      # rubocop:disable Style/CaseEquality
      @ignores.any? { |rule| rule === field }
      # rubocop:enable Style/CaseEquality
    end

    def self.ignore_fields(*fields)
      @ignores = Array(fields)
    end

    @ignores = []
  end
end
