# frozen_string_literal: true

require "active_support"

module Anony
  class Result
    FAILED = "failed"
    DESTROYED = "destroyed"
    OVERWRITTEN = "overwritten"
    SKIPPED = "skipped"

    attr_reader :status, :fields, :error, :record

    delegate :failed?, :overwritten?, :skipped?, :destroyed?, to: :status

    def self.failed(error, record)
      new(FAILED, record: record, error: error)
    end

    def self.overwritten(fields, record)
      new(OVERWRITTEN, record: record, fields: fields)
    end

    def self.skipped(record)
      new(SKIPPED, record: record)
    end

    def self.destroyed(record)
      new(DESTROYED, record: record)
    end

    private def initialize(status, record:, fields: [], error: nil)
      raise ArgumentError, "No error provided" if status == FAILED && error.nil?

      @status = ActiveSupport::StringInquirer.new(status)
      @fields = fields
      @error = error
      @record = record
    end
  end
end
