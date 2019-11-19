# frozen_string_literal: true

module Anony
  module Config
    mattr_accessor :ignores
    mattr_accessor :email_template
    mattr_accessor :phone_number

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

    def self.register_strategy(name, &block)
      @strategies[name] = block
    end

    def self.strategy(name)
      @strategies[name]
    end

    @strategies = {}

    self.email_template = "%s@example.com"
    self.phone_number = "+1 617 555 1294"
  end
end
