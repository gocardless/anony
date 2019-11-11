# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Anonymisable do
  module StubAnoynmiser
    def self.call(*_)
      "OVERWRITTEN DATA"
    end
  end

  context "valid model anonymisation" do
    let(:model) do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field
        attr_accessor :b_field
        attr_accessor :c_field
        attr_accessor :d_field

        anonymise do
          with_strategy StubAnoynmiser, :a_field
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

        def save!
          true
        end
      end

      klass.new
    end

    before do
      model.a_field = double
      model.b_field = "abc"
      model.c_field = double
      model.d_field = double
    end

    describe "#anonymise!" do
      it "anoynmises fields" do
        expect { model.anonymise! }.
          to change(model, :a_field).to("OVERWRITTEN DATA").
          and change(model, :b_field).to("cba")
      end

      it "saves the model" do
        expect(model).to receive(:save!)

        model.anonymise!
      end

      context "`do_not_anonymise` fields" do
        it { expect { model.anonymise! }.to_not change(model, :c_field) }
        it { expect { model.anonymise! }.to_not change(model, :d_field) }
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

  context "destroy on anonymise" do
    let(:model) do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field

        anonymise do
          destroy
        end

        def destroy!
          true
        end
      end

      klass.new
    end

    describe "#anonymise!" do
      it "destroys the model" do
        expect(model).to receive(:destroy!)

        model.anonymise!
      end
    end

    describe "#valid_anonymisation?" do
      it "is valid" do
        expect(model).to be_valid_anonymisation
      end
    end
  end

  context "invalid model anonymisation" do
    describe "#valid_anonymisation?" do
      let(:model) do
        klass = Class.new do
          include Anony::Anonymisable

          attr_accessor :a_field
          attr_accessor :b_field

          anonymise do
            with_strategy StubAnoynmiser, :a_field
          end

          def self.column_names
            %w[a_field b_field]
          end
        end

        klass.new
      end

      it "fails" do
        expect(model).to_not be_valid_anonymisation
      end
    end
  end

  context "no anonymise block" do
    describe "#valid_anonymisation?" do
      let(:model) do
        klass = Class.new do
          include Anony::Anonymisable

          attr_accessor :a_field
          attr_accessor :b_field

          def self.column_names
            %w[a_field b_field]
          end
        end

        klass.new
      end

      it "fails" do
        expect(model).to_not be_valid_anonymisation
      end
    end
  end

  context "when a strategy is specified after destroy" do
    it "throws an exception" do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field

        anonymise do
          destroy
        end
      end

      expect { klass.anonymise { nilable :a_field } }.to raise_error(
        ArgumentError, "Can't specify destroy and strategies for fields"
      )
    end
  end

  context "when a strategy is specified before destroy" do
    it "throws an exception" do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field

        anonymise do
          nilable :a_field
        end
      end

      expect { klass.anonymise { destroy } }.to raise_error(
        ArgumentError, "Can't specify destroy and strategies for fields"
      )
    end
  end

  context "with ignored fields in Anony::Config" do
    around do |example|
      begin
        original_ignores = Anony::Config.ignores
        example.call
      ensure
        Anony::Config.ignores = original_ignores
      end
    end

    before { Anony::Config.ignore_fields(:id) }

    it "throws an exception" do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :id
      end

      expect { klass.anonymise { ignore :id } }.to raise_error(
        ArgumentError, "Cannot ignore [:id] (fields already ignored in Anony::Config)"
      )
    end

    it "doesn't warn about ignored :id field" do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :id, :name

        anonymise { with_strategy(StubAnoynmiser, :name) }

        def self.column_names
          %w[id name]
        end
      end

      expect(klass.new).to be_valid_anonymisation
    end
  end

  context "with two models" do
    let(:a_class) do
      Class.new do
        include Anony::Anonymisable
        attr_accessor :a_field

        anonymise do
          with_strategy StubAnoynmiser, :a_field
        end

        def self.column_names
          %w[a_field]
        end
      end
    end

    let(:b_class) do
      Class.new do
        include Anony::Anonymisable
        attr_accessor :b_field

        anonymise do
          with_strategy StubAnoynmiser, :b_field
        end

        def self.column_names
          %w[b_field]
        end
      end
    end

    it "models do not leak configuration" do
      #  We had a case where these leaked, so we want to explicitly test it.
      expect(a_class.anonymisable_fields).to match(a_field: anything)
      expect(b_class.anonymisable_fields).to match(b_field: anything)
    end
  end

  describe "#with_strategy" do
    let(:config) { Anony::AnonymisableConfig.new }

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

    context "two arguments" do
      it "registers the field to the strategy" do
        config.with_strategy(StubAnoynmiser, :field)
        expect(config.anonymisable_fields).to eq(field: StubAnoynmiser)
      end

      it "with a block" do
        config.with_strategy(:foo, :bar) { |v| v }
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

  describe "helper methods" do
    let(:model) do
      klass = Class.new do
        include Anony::Anonymisable

        attr_accessor :null, :hexy, :mailo, :phone_numba

        anonymise do
          nilable :null
          hex :hexy
          email :mailo
          phone_number :phone_numba
        end

        def self.column_names
          %w[null hexy mailo phone_numba]
        end

        alias_method :read_attribute, :send
        def write_attribute(field, value)
          send("#{field}=", value)
        end

        def save!
          true
        end
      end

      klass.new
    end

    before do
      model.null = "foo"
      model.hexy = "bar"
      model.mailo = "baz"
      model.phone_numba = "qux"
    end

    it "calls the relevant anonymisers" do
      expect(Anony::Nilable).to receive(:call).with("foo")
      expect_any_instance_of(Anony::OverwriteHex).to receive(:call).with("bar")
      expect(Anony::AnonymisedEmail).to receive(:call).with("baz")
      expect(Anony::AnonymisedPhoneNumber).to receive(:call).with("qux")

      model.anonymise!
    end
  end
end
