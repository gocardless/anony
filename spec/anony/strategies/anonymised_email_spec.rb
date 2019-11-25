# frozen_string_literal: true

require "spec_helper"

RSpec.describe "email strategy" do # rubocop:disable RSpec/DescribeClass
  subject(:result) { Anony::Strategies[:email].call(value) }

  let(:value) { "old value" }

  it { is_expected.to match(/^[0-9a-f\-]+@example.com$/) }
end
