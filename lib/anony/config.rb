# frozen_string_literal: true

module Anony
  module Config
    mattr_accessor :ignores
    mattr_accessor :email_template

    def self.ignore?(field)
      # In this case, we want to support literal matches, regular expressions and blocks,
      # all of which are helpfully handled by Object#===.
      #
      # rubocop:disable Style/CaseEquality
      ignores.any? { |rule| rule === field }
      # rubocop:enable Style/CaseEquality
    end

    def self.ignore_fields(*fields)
      self.ignores = Array(fields)
    end

    self.ignores = []
    self.email_template = "%s@example.com"
  end
end
