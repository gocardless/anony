# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::OverwriteHex do
  describe ".call" do
    subject(:result) { described_class.new(36).call(value) }

    let(:value) { "old value" }

    it { is_expected.to match(/^\h{36}$/) }
  end
end
