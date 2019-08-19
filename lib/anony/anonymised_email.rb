# frozen_string_literal: true

require "securerandom"

module Anony
  module AnonymisedEmail
    def self.call(_value, _)
      "anonymous+#{SecureRandom.uuid}@gocardless.com"
    end
  end
end
