# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Strategies::Constant do
  describe ".call" do
    subject(:result) { described_class.new(constant).call(value) }

    let(:value) { "old value" }
    let(:constant) { "new value" }

    it { is_expected.to be constant }
  end
end
