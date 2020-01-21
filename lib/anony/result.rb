# frozen_string_literal: true

module Anony
  class Result
    attr_reader :fields, :error

    def self.failed(error)
      new(error: error)
    end

    def self.anonymised(fields)
      new(fields: fields)
    end

    def self.skipped
      new(skipped: true)
    end

    def self.deleted
      new(deleted: true)
    end

    def failed?
      error.present?
    end

    def anonymised?
      fields.any?
    end

    def skipped?
      @skipped
    end

    def deleted?
      @deleted
    end

    private def initialize(fields: {}, error: nil, skipped: false, deleted: false)
      @fields = fields
      @error = error
      @skipped = skipped
      @deleted = deleted
    end
  end
end
