# frozen_string_literal: true

require "spec_helper"
require_relative "helpers/database"

RSpec.describe Anony::Result do
  let(:field_values) do
    {
      name: "OVERWRITTEN",
      email: "OVERWRITTEN",
    }
  end

  shared_context "with model instance" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        def self.name
          "Employee"
        end

        self.table_name = :employees
      end
    end

    let(:model) { klass.new }
  end

  context "anonymised" do
    include_context "with model instance"
    let(:result) { described_class.overwritten(field_values, model) }

    it "has enumbeable state" do
      expect(result.status).to eq("overwritten")
    end

    it "responds to .overwritten?" do
      expect(result).to be_overwritten
    end

    it "contains the model" do
      expect(result.record).to be model
    end
  end

  context "deleted" do
    include_context "with model instance"
    let(:result) { described_class.destroyed(model) }

    it "has enumbeable state" do
      expect(result.status).to eq("destroyed")
    end

    it "responds to .destroyed?" do
      expect(result).to be_destroyed
    end

    it "has no fields" do
      expect(result.fields).to be_empty
    end

    it "contains the model" do
      expect(result.record).to be model
    end
  end

  context "skipped" do
    include_context "with model instance"
    let(:result) { described_class.skipped(model) }

    it "has enumbeable state" do
      expect(result.status).to eq("skipped")
    end

    it "responds to .skipped?" do
      expect(result).to be_skipped
    end

    it "has no fields" do
      expect(result.fields).to be_empty
    end

    it "contains the model" do
      expect(result.record).to be model
    end
  end

  context "failed" do
    include_context "with model instance"
    let(:error) { anything }
    let(:result) { described_class.failed(error, model) }

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

    it "contains the model" do
      expect(result.record).to be model
    end
  end
end
