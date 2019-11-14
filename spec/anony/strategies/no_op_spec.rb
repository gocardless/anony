# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Strategies::NoOp do
  describe ".call" do
    subject(:result) { described_class.call(value) }

    let(:value) { "old value" }

    it { is_expected.to be value }
  end
end
