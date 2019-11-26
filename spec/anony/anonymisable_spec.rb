# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Anonymisable do
  module StubAnoynmiser
    def self.call(*_)
      "OVERWRITTEN DATA"
    end
  end

  context "valid model anonymisation" do
    let(:klass) do
      Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field
        attr_accessor :b_field
        attr_accessor :c_field
        attr_accessor :d_field
        attr_accessor :ignore_one
        attr_accessor :ignore_two

        anonymise do
          with_strategy StubAnoynmiser, :a_field
          with_strategy(:b_field) { |v, _| v.reverse }
          with_strategy(:c_field) { some_instance_method? ? "yes" : "no" }
          with_strategy 321, :d_field

          with_strategy "foo", :missing_field

          ignore :ignore_one, :ignore_two
        end

        def self.column_names
          %w[a_field b_field c_field d_field ignore_one ignore_two]
        end

        alias_method :read_attribute, :send
        def write_attribute(field, value)
          send("#{field}=", value)
        end

        def save!
          true
        end

        def some_instance_method?
          true
        end
      end
    end

    let(:model) { klass.new }

    before do
      model.a_field = double
      model.b_field = "abc"
      model.c_field = double
      model.d_field = 123
      model.ignore_one = model.ignore_two = double
    end

    describe "#anonymise!" do
      it "anoynmises fields" do
        expect { model.anonymise! }.
          to change(model, :a_field).to("OVERWRITTEN DATA").
          and change(model, :b_field).to("cba").
          and change(model, :c_field).to("yes").
          and change(model, :d_field).to(321)
      end

      it "saves the model" do
        expect(model).to receive(:save!)

        model.anonymise!
      end

      context "ignored fields" do
        it { expect { model.anonymise! }.to_not change(model, :ignore_one) }
        it { expect { model.anonymise! }.to_not change(model, :ignore_two) }
      end
    end

    describe "#valid_anonymisation?" do
      context "all fields are handled" do
        it "is valid" do
          expect(klass).to be_valid_anonymisation
        end
      end
    end
  end

  context "destroy on anonymise" do
    let(:klass) do
      Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field

        anonymise do
          destroy
        end

        def destroy!
          true
        end
      end
    end

    let(:model) { klass.new }

    describe "#anonymise!" do
      it "destroys the model" do
        expect(model).to receive(:destroy!)

        model.anonymise!
      end
    end

    describe "#valid_anonymisation?" do
      it "is valid" do
        expect(klass).to be_valid_anonymisation
      end
    end
  end

  context "invalid model anonymisation" do
    let(:klass) do
      Class.new do
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
    end

    describe "#valid_anonymisation?" do
      it "fails" do
        expect(klass).to_not be_valid_anonymisation
      end
    end

    describe "anonymise!" do
      let(:model) { klass.new }

      it "throws an exception" do
        expect { model.anonymise! }.to raise_error(
          Anony::FieldException, "Invalid anonymisation strategy for field(s) [:b_field]"
        )
      end
    end
  end

  context "no anonymise block" do
    describe "#valid_anonymisation?" do
      let(:klass) do
        Class.new do
          include Anony::Anonymisable

          attr_accessor :a_field
          attr_accessor :b_field

          def self.column_names
            %w[a_field b_field]
          end
        end
      end

      it "fails" do
        expect(klass).to_not be_valid_anonymisation
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

  context "when anonymised_at column is present" do
    let(:klass) do
      Class.new do
        include Anony::Anonymisable

        attr_accessor :a_field, :anonymised_at

        anonymise do
          nilable :a_field
        end

        def self.column_names
          %w[a_field anonymised_at]
        end

        alias_method :read_attribute, :send
        def write_attribute(field, value)
          send("#{field}=", value)
        end

        def save!
          true
        end
      end
    end

    it "is a valid anonymisation even though column is not configured" do
      expect(klass).to be_valid_anonymisation
    end

    it "sets anonymised_at = Time.zone.now when anonymising" do
      model = klass.new
      expect { model.anonymise! }.
        to change { model.anonymised_at }.
        from(nil).
        to be_within(1).of(Time.now)
    end
  end

  context "with ignored fields in Anony::Config" do
    around do |example|
      original_ignores = Anony::Config.ignores
      example.call
    ensure
      Anony::Config.ignores = original_ignores
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

      expect(klass).to be_valid_anonymisation
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

    # rubocop:disable RSpec/MultipleExpectations
    it "models do not leak configuration" do
      #  We had a case where these leaked, so we want to explicitly test it.
      expect(a_class.anonymisable_fields).to match(a_field: anything)
      expect(b_class.anonymisable_fields).to match(b_field: anything)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
