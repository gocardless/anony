# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Strategies::Nilable do
  describe ".call" do
    subject(:result) { described_class.call(value) }

    let(:value) { "old value" }

    it { is_expected.to be nil }
  end
end
