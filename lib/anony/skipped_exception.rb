# frozen_string_literal: true

module Anony
  class SkippedException < StandardError
    def initialize
      super("Anonymisation skipped due to matching skip_if filter")
    end
  end
end
