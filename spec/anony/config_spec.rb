# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Config do
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
end
