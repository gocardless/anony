# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Anonymisable do
  module StubAnoynmiser
    def self.call(*_)
      "OVERWRITTEN DATA"
    end
  end

  context "valid model anonymisation" do
    class StubModel
      include Anony::Anonymisable

      attr_accessor :a_field
      attr_accessor :b_field
      attr_accessor :c_field
      attr_accessor :d_field

      anonymise do
        with_strategy :a_field, StubAnoynmiser
        with_strategy(:b_field) { |v, _| v.reverse }
        ignore :c_field, :d_field
      end

      def self.column_names
        %w[a_field b_field c_field d_field]
      end

      alias_method :read_attribute, :send
      def write_attribute(field, value)
        send("#{field}=", value)
      end
    end

    let(:model) { StubModel.new }

    before do
      model.a_field = double
      model.b_field = "abc"
      model.c_field = double
      model.d_field = double
    end

    describe "#anonymise_field" do
      it "anonymises field `a`" do
        model.anonymise_field(:a_field)
        expect(model.a_field).to eq("OVERWRITTEN DATA")
      end

      it "raises on invalid fields" do
        expect { model.anonymise_field(:not_a_field) }.
          to raise_error(Anony::FieldException)
      end
    end

    describe "#anonymise" do
      it "anoynmises fields" do
        expect { model.anonymise }.
          to change(model, :a_field).to("OVERWRITTEN DATA").
          and change(model, :b_field).to("cba")
      end

      context "`do_not_anonymise` fields" do
        it { expect { model.anonymise }.to_not change(model, :c_field) }
        it { expect { model.anonymise }.to_not change(model, :d_field) }
      end
    end

    describe "#valid_anonymisation?" do
      context "all fields are handled" do
        it "is valid" do
          expect(model).to be_valid_anonymisation
        end
      end
    end
  end

  context "invalid model anonymisation" do
    describe "#valid_anonymisation?" do
      class InvalidStubModel
        include Anony::Anonymisable

        attr_accessor :a_field
        attr_accessor :b_field

        anonymise do
          with_strategy :a_field, StubAnoynmiser
        end

        def self.column_names
          %w[a_field b_field]
        end
      end

      let(:model) { InvalidStubModel.new }

      it "fails" do
        expect(model).to_not be_valid_anonymisation
      end
    end
  end

  context "with two models" do
    class AClass
      include Anony::Anonymisable
      attr_accessor :a_field

      anonymise do
        with_strategy :a_field, StubAnoynmiser
      end

      def self.column_names
        %w[a_field]
      end
    end

    class BClass
      include Anony::Anonymisable
      attr_accessor :b_field

      anonymise do
        with_strategy :b_field, StubAnoynmiser
      end

      def self.column_names
        %w[b_field]
      end
    end

    it "models do not leak configuration" do
      #  We had a case where these leaked, so we want to explicitly test it.
      expect(AClass.anonymisable_fields).to match(a_field: anything)
      expect(BClass.anonymisable_fields).to match(b_field: anything)
    end
  end
end
