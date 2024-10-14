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

  shared_context "without model instance" do
    before do
      allow(described_class::RESULT_DEPRECATION).to receive(:warn)
    end
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
    shared_examples_for "anonymised result" do
      it "has enumbeable state" do
        expect(result.status).to eq("overwritten")
      end

      it "responds to .overwritten?" do
        expect(result).to be_overwritten
      end
    end

    context "without record" do
      include_context "without model instance"
      let(:result) { described_class.overwritten(field_values) }

      it_behaves_like "anonymised result"
    end

    context "with record" do
      include_context "with model instance"
      let(:result) { described_class.overwritten(field_values, model) }

      it_behaves_like "anonymised result"

      it "contains the model" do
        expect(result.record).to be model
      end
    end
  end

  context "deleted" do
    shared_examples_for "destroyed result" do
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

    context "without record" do
      include_context "without model instance"
      let(:result) { described_class.destroyed }

      it_behaves_like "destroyed result"
    end

    context "with record" do
      include_context "with model instance"
      let(:result) { described_class.destroyed(model) }

      it_behaves_like "destroyed result"

      it "contains the model" do
        expect(result.record).to be model
      end
    end
  end

  context "skipped" do
    shared_examples_for "skipped result" do
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

    context "without record" do
      include_context "without model instance"
      let(:result) { described_class.skipped }

      it_behaves_like "skipped result"
    end

    context "with record" do
      include_context "with model instance"
      let(:result) { described_class.skipped(model) }

      it_behaves_like "skipped result"

      it "contains the model" do
        expect(result.record).to be model
      end
    end
  end

  context "failed" do
    let(:error) { anything }

    shared_examples_for "failed result" do
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

    context "without record" do
      include_context "without model instance"
      let(:result) { described_class.failed(error) }

      it_behaves_like "failed result"
    end

    context "with record" do
      include_context "with model instance"
      let(:result) { described_class.failed(error, model) }

      it_behaves_like "failed result"

      it "contains the model" do
        expect(result.record).to be model
      end
    end
  end
end
