# frozen_string_literal: true

require "bundler/setup"
require "anony"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
