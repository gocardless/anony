# frozen_string_literal: true

require "anony/config"

Anony::Config.register_strategy(:nilable) { |_value| nil }
