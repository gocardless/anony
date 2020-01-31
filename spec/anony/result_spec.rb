# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Result do
  let(:field_values) do
    {
      name: "OVERWRITTEN",
      email: "OVERWRITTEN",
    }
  end

  context "anonymised" do
    let(:result) { described_class.overwritten(field_values) }

    it "has enumbeable state" do
      expect(result.status).to eq("overwritten")
    end

    it "responds to .overwritten?" do
      expect(result).to be_overwritten
    end
  end

  context "deleted" do
    let(:result) { described_class.destroyed }

    it "has enumbeable state" do
      expect(result.status).to eq("destroyed")
    end

    it "responds to .destroyed?" do
      expect(result).to be_destroyed
    end

    it "has no fields" do
      expect(result.fields).to be_empty
    end
  end

  context "skipped" do
    let(:result) { described_class.skipped }

    it "has enumbeable state" do
      expect(result.status).to eq("skipped")
    end

    it "responds to .skipped?" do
      expect(result).to be_skipped
    end

    it "has no fields" do
      expect(result.fields).to be_empty
    end
  end

  context "failed" do
    let(:error) { anything }
    let(:result) { described_class.failed(error) }

    it "has an error" do
      expect(result.error).to eq(error)
    end

    it "has enumbeable state" do
      expect(result.status).to eq("failed")
    end

    it "responds to .failed?" do
      expect(result).to be_failed
    end

    context "without an error" do
      it "raises an exception" do
        expect { described_class.failed(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
