# frozen_string_literal: true

require "active_support"

module Anony
  class Result
    FAILED = "failed"
    DESTROYED = "destroyed"
    OVERWRITTEN = "overwritten"
    SKIPPED = "skipped"

    attr_reader :status, :fields, :error
    delegate :failed?, :overwritten?, :skipped?, :destroyed?, to: :status

    def self.failed(error)
      new(FAILED, error: error)
    end

    def self.overwritten(fields)
      new(OVERWRITTEN, fields: fields)
    end

    def self.skipped
      new(SKIPPED)
    end

    def self.destroyed
      new(DESTROYED)
    end

    private def initialize(status, fields: [], error: nil)
      raise ArgumentError, "No error provided" if status == FAILED && error.nil?

      @status = ActiveSupport::StringInquirer.new(status)
      @fields = fields
      @error = error
    end
  end
end
