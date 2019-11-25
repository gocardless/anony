# frozen_string_literal: true

require "spec_helper"

RSpec.describe "current_datetime strategy" do # rubocop:disable RSpec/DescribeClass
  subject(:result) { Anony::Strategies[:current_datetime].call(value) }

  let(:value) { "old value" }

  it { is_expected.to be_within(1).of(Time.zone.now) }

  context "when Rails timezone is not set" do
    before { allow(Time).to receive(:zone).and_return(nil) }

    it "raises an error" do
      expect { result }.
        to raise_error(ArgumentError, "Ensure Rails' config.time_zone is set")
    end
  end
end
