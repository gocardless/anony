# frozen_string_literal: true

require "active_support/core_ext/time/zones"

module Anony
  module Strategies
    module CurrentDatetime
      def self.call(_value)
        tz = Time.zone
        raise ArgumentError, "Ensure Rails' config.time_zone is set" unless tz

        tz.now
      end
    end
  end
end
