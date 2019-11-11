# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Config do
  around do |example|
    begin
      original_ignores = described_class.ignores
      example.call
    ensure
      described_class.ignores = original_ignores
    end
  end

  describe ".ignore?" do
    subject(:ignore?) { described_class.ignore?(field) }

    before { described_class.ignore_fields(:a, /b/, ->(f) { f.to_s == "c" }) }

    context "with :a symbol" do
      let(:field) { :a }

      it { is_expected.to be true }
    end

    context "with :b regexp" do
      let(:field) { :b }

      it { is_expected.to be true }
    end

    context "with :c lambda" do
      let(:field) { :c }

      it { is_expected.to be true }
    end

    context "with an unregistered field" do
      let(:field) { :d }

      it { is_expected.to be false }
    end
  end

  describe ".ignores" do
    subject(:ignores) { described_class.ignores }

    before { described_class.ignore_fields(:a) }

    it "gives the current configuration back" do
      expect(ignores).to eq([:a])
    end
  end
end
