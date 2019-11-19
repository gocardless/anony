# frozen_string_literal: true

require "spec_helper"

RSpec.describe "nilable" do
  subject(:result) { Anony::Config.strategy(:nilable).call(value) }

  let(:value) { "old value" }

  it { is_expected.to be nil }
end
