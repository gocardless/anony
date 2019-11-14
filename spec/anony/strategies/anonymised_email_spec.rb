# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Strategies::AnonymisedEmail do
  describe ".call" do
    subject(:result) { described_class.call(value) }

    around do |example|
      original = Anony::Config.email_template
      Anony::Config.email_template = "anonymous+%s@test-domain.com"

      example.run

      Anony::Config.email_template = original
    end

    let(:value) { "old value" }

    it { is_expected.to match(/^anonymous\+[0-9a-f\-]+@test-domain.com$/) }
  end
end
