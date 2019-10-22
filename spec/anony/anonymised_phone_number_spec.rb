# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::AnonymisedPhoneNumber do
  describe ".call" do
    subject(:result) { described_class.call(value) }

    around do |example|
      original = Anony::Config.phone_number
      Anony::Config.phone_number = "+12 3456 7891"

      example.run

      Anony::Config.phone_number = original
    end

    let(:value) { "old phone number" }

    it { is_expected.to eq("+12 3456 7891") }
  end
end
