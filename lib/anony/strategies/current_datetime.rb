# frozen_string_literal: true

require "active_support/core_ext/time/zones"

Anony::Strategies.register(:current_datetime) do |_original|
  tz = Time.zone
  raise ArgumentError, "Ensure Rails' config.time_zone is set" unless tz

  tz.now
end
