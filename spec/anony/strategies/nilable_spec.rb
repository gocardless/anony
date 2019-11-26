# frozen_string_literal: true

require "spec_helper"

RSpec.describe "nilable strategy" do # rubocop:disable RSpec/DescribeClass
  subject(:result) { Anony::Strategies[:nilable].call(value) }

  let(:value) { "old value" }

  it { is_expected.to be nil }
end
