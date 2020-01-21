# frozen_string_literal: true

require 'active_support'

module Anony
  class Result
    FAILED = 'failed'.freeze
    DELETED = 'deleted'.freeze
    ANONYMISED = 'anonymised'.freeze
    SKIPPED = 'skipped'.freeze

    attr_reader :fields, :error

    def self.failed(error)
      new(FAILED, error: error)
    end

    def self.anonymised(fields)
      new(ANONYMISED, fields: fields)
    end

    def self.skipped
      new(SKIPPED)
    end

    def self.deleted
      new(DELETED)
    end

    def state
      @state
    end

    delegate :failed?, :anonymised?, :skipped?, :deleted?, to: :state

    private def initialize(state, fields: {}, error: nil)
      raise ArgumentError.new('No error provided') if state == FAILED && error.nil?

      @state = ActiveSupport::StringInquirer.new(state)
      @fields = fields
      @error = error
    end
  end
end
