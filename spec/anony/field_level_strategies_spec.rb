# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::FieldLevelStrategies do
  describe ".register" do
    let(:name) { :reverse }

    after do
      described_class.undef_method(name)
    rescue StandardError
      nil
    end

    context "with a block" do
      subject(:register) { described_class.register(name, &:reverse) }

      it "registers the strategy" do
        register
        expect(Anony::Strategies::Fields.instance_methods).to include(:reverse)
      end
    end

    context "with a constant value" do
      subject(:register) { described_class.register(name, 4) }

      it "registers the strategy" do
        register
        expect(Anony::Strategies::Fields.instance_methods).to include(:reverse)
      end
    end

    context "with a strategy klass" do
      subject(:register) do
        strategy = Class.new
        described_class.register(name, strategy)
      end

      it "registers the strategy" do
        register
        expect(Anony::Strategies::Fields.instance_methods).to include(:reverse)
      end
    end

    context "without a constant, klass or block" do
      it "throws an error" do
        expect { described_class.register(name) }.to raise_error(ArgumentError, /block/)
      end
    end
  end

  describe ".[]" do
    context "after receiving a block" do
      let(:block) { ->(a) { a } }

      before { described_class.register(:a, block) }

      it "returns the block" do
        expect(described_class[:a]).to eq(block)
      end
    end

    context "after receiving a constant value" do
      let(:constant) { 4 }

      before { described_class.register(:a, constant) }

      it "returns the block" do
        expect(described_class[:a]).to eq(constant)
      end
    end

    context "with an unknown strategy" do
      it "throws an error" do
        expect { described_class[:whatever] }.to raise_error(ArgumentError, /whatever/)
      end
    end
  end

  describe ":email strategy" do
    subject(:result) { described_class[:email].call(value) }

    let(:value) { "old value" }

    it { is_expected.to match(/^[0-9a-f\-]+@example.com$/) }
  end

  describe ":phone_number strategy" do
    subject(:result) { described_class[:phone_number] }

    it { is_expected.to eq("+1 617 555 1294") }
  end

  describe ":current_datetime strategy" do
    subject(:result) do
      model.instance_exec(&described_class[:current_datetime])
    end

    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees
      end
    end

    let(:model) { klass.new }

    let(:value) { "old value" }

    it { is_expected.to be_within(1).of(Time.now) }
  end

  describe ":nilable strategy" do
    subject(:result) { described_class[:nilable].call(value) }

    let(:value) { "old value" }

    it { is_expected.to be nil }
  end

  describe ":no_op strategy" do
    subject(:result) { described_class[:no_op].call(value) }

    let(:value) { "old value" }

    it { is_expected.to be value }
  end
end
