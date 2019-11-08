# frozen_string_literal: true

module Anony
  module AnonymisedPhoneNumber
    def self.call(_value)
      Anony::Config.phone_number
    end
  end
end
