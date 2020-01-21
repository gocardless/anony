# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Result do
  context "anonymises a record" do
    let(:result) { described_class.anonymised(field_values) }

    let(:field_values) do
      {
        name: "OVERWRITTEN",
        email: "OVERWRITTEN",
      }
    end

    it "provides new values and keys" do
      expect(result.fields).to eq(field_values)
    end

    it "is anonymised" do
      expect(result).to be_anonymised
    end

    it "is not deleted" do
      expect(result).to_not be_deleted
    end

    it "is not skipped?" do
      expect(result).to_not be_skipped
    end

    it "is not failed" do
      expect(result).to_not be_failed
    end
  end

  context "skipping a record" do
    let(:result) { described_class.skipped }

    it "is skipped?" do
      expect(result).to be_skipped
    end

    it "is not anonymised?" do
      expect(result).to_not be_anonymised
    end

    it "is not deleted" do
      expect(result).to_not be_deleted
    end

    it "is not failed" do
      expect(result).to_not be_failed
    end
  end

  context "deleting a record" do
    let(:result) { described_class.deleted }

    it "is deleted?" do
      expect(result).to be_deleted
    end

    it "is not anonymised?" do
      expect(result).to_not be_anonymised
    end

    it "is not skipped?" do
      expect(result).to_not be_skipped
    end

    it "is not failed" do
      expect(result).to_not be_failed
    end
  end

  context "it fails" do
    let(:result) { described_class.failed(error) }

    let(:error) do
      anything
    end

    it "is failed" do
      expect(result).to be_failed
    end

    it "reports the error" do
      expect(result.error).to be(anything)
    end

    it "is not anonymised" do
      expect(result).to_not be_anonymised
    end

    it "is not deleted" do
      expect(result).to_not be_deleted
    end

    it "is not skipped?" do
      expect(result).to_not be_skipped
    end
  end
end
