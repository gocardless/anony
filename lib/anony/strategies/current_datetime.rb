# frozen_string_literal: true

Anony::Strategies.register(:current_datetime) do |_original|
  current_time_from_proper_timezone
end
