# frozen_string_literal: true

require "active_support"

module Anony
  class Result
    FAILED = "failed"
    DELETED = "deleted"
    ANONYMISED = "anonymised"
    SKIPPED = "skipped"

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

    attr_reader :status

    delegate :failed?, :anonymised?, :skipped?, :deleted?, to: :status

    private def initialize(status, fields: {}, error: nil)
      raise ArgumentError, "No error provided" if status == FAILED && error.nil?

      @status = ActiveSupport::StringInquirer.new(status)
      @fields = fields
      @error = error
    end
  end
end
