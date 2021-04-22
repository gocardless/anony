# frozen_string_literal: true

require "spec_helper"
require_relative "../helpers/database"

RSpec.describe Anony::Strategies::Overwrite do
  module StubAnoynmiser
    def self.call(*_)
      "OVERWRITTEN DATA"
    end
  end

  let(:model_klass) { double }
  let(:config) { described_class.new(model_klass) }

  describe "#with_strategy" do
    context "no arguments" do
      it "throws an argumenterror" do
        expect { config.with_strategy }.to raise_error(ArgumentError)
      end
    end

    context "strategy without any fields" do
      it "throws an argumenterror" do
        expect { config.with_strategy(StubAnoynmiser) }.to raise_error(ArgumentError)
      end
    end

    context "field without any strategy" do
      it "throws an argumenterror" do
        expect { config.with_strategy(:field) }.to raise_error(ArgumentError)
      end
    end

    context "defining a strategy on a field which already has one defined" do
      before do
        config.with_strategy(StubAnoynmiser, :field)
      end

      it "throws an duplicate_strategy_exception" do
        expect { config.no_op(:field) }.
          to raise_error(Anony::DuplicateStrategyException)
      end
    end

    it "with an array of fields and no block / strategy" do
      expect { config.with_strategy(%i[foo bar]) }.to raise_error(ArgumentError)
    end

    context "two arguments" do
      it "registers the field to the strategy" do
        config.with_strategy(StubAnoynmiser, :field)
        expect(config.anonymisable_fields).to eq(field: StubAnoynmiser)
      end

      it "with a block" do
        config.with_strategy(:foo, :bar) { |v| v }
        expect(config.anonymisable_fields.keys).to eq(%i[foo bar])
      end

      it "with a strategy and an array of fields" do
        config.with_strategy(StubAnoynmiser, %i[foo bar])
        expect(config.anonymisable_fields).to eq(
          foo: StubAnoynmiser,
          bar: StubAnoynmiser,
        )
      end

      it "with a block and an array of fields" do
        config.with_strategy(%i[foo bar]) { |v| v }
        expect(config.anonymisable_fields.keys).to eq(%i[foo bar])
      end
    end

    context "a strategy for two fields" do
      it "registers them correctly" do
        config.with_strategy(StubAnoynmiser, :foo, :bar)
        expect(config.anonymisable_fields).to eq(foo: StubAnoynmiser, bar: StubAnoynmiser)
      end
    end
  end

  describe "#apply" do
    let(:model_klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :only_anonymised
        anonymise do
          overwrite { }
        end
      end
    end

    let(:instance) { model_klass.new }

    it "idempotently attaches the anonymised_at rule once" do
      3.times { config.apply(instance) }
    end
  end

  context "when using dynamic strategies" do
    before { allow(model_klass).to receive(:column_names).and_return([]) }

    it "is not possible to override the builtin methods like :valid?" do
      Anony::FieldLevelStrategies.register(:valid?) { raise "Oops!" }
      expect { config.valid? }.to_not raise_error
    end
  end
end
