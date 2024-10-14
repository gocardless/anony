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

    RESULT_DEPRECATION = ActiveSupport::Deprecation.new("2.0.0", "anony")

    def self.failed(error, record = nil)
      new(FAILED, record: record, error: error)
    end

    def self.overwritten(fields, record = nil)
      new(OVERWRITTEN, record: record, fields: fields)
    end

    def self.skipped(record = nil)
      new(SKIPPED, record: record)
    end

    def self.destroyed(record = nil)
      new(DESTROYED, record: record)
    end

    private def initialize(status, record:, fields: [], error: nil)
      raise ArgumentError, "No error provided" if status == FAILED && error.nil?

      if record.nil?
        RESULT_DEPRECATION.warn(
          "Creating a Result without a reference to the record being anonymised is deprecated " \
          "and will be removed in future versions",
        )
      end

      @status = ActiveSupport::StringInquirer.new(status)
      @fields = fields
      @error = error
      @record = record
    end
  end
end
