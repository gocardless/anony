# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::AnonymisedEmail do
  describe ".call" do
    subject(:result) { described_class.call(value) }

    let(:value) { "old value" }

    it { is_expected.to match(/^anonymous\+[0-9a-f\-]+@example.com$/) }
  end
end
