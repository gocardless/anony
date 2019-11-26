# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Strategies do
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
        expect(Anony::DSL.instance_methods).to include(:reverse)
      end
    end

    context "with a constant value" do
      subject(:register) { described_class.register(name, 4) }

      it "registers the strategy" do
        register
        expect(Anony::DSL.instance_methods).to include(:reverse)
      end
    end

    context "with a strategy klass" do
      subject(:register) do
        strategy = Class.new
        described_class.register(name, strategy)
      end

      it "registers the strategy" do
        register
        expect(Anony::DSL.instance_methods).to include(:reverse)
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
end
