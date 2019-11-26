# frozen_string_literal: true

require "securerandom"

require_relative "../strategies"

Anony::Strategies.register(:email) do
  sprintf("%<random>s@example.com", random: SecureRandom.uuid)
end
