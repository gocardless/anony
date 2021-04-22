# frozen_string_literal: true

module Anony
  # This exception is thrown if you call `.anonymised?` on a model that does not
  # have an `anonymised_at` column.
  class AnonymisationNotKnownException < StandardError
    def initialize
      super("Cannot determine if a record has been anonymised without an `anonymised_at` column.")
    end
  end
end
