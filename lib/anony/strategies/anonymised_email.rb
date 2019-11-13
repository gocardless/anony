# frozen_string_literal: true

require "securerandom"

module Anony
  module Strategies
    module AnonymisedEmail
      def self.call(_value)
        Anony::Config.email_template % SecureRandom.uuid
      end
    end
  end
end
