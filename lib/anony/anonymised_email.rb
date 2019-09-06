# frozen_string_literal: true

require "securerandom"

module Anony
  module AnonymisedEmail
    def self.call(_value)
      "anonymous+#{SecureRandom.uuid}@example.com"
    end
  end
end
