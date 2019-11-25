# frozen_string_literal: true

require "spec_helper"

RSpec.describe "phone_number strategy" do # rubocop:disable RSpec/DescribeClass
  subject(:result) { Anony::Strategies[:phone_number] }

  it { is_expected.to eq("+1 617 555 1294") }
end
