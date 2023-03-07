# frozen_string_literal: true

module Anony
  class NotAnonymisableException < StandardError
    def initialize(record)
      @record = record
      super("Record does not implement anonymise!.
            Have you included Anony::Anonymisable and a config?")
    end
  end
end
