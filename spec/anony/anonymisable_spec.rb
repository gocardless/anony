# frozen_string_literal: true

require "spec_helper"
require_relative "helpers/database"

RSpec.describe Anony::Anonymisable do
  module StubAnoynmiser
    def self.call(*_)
      "OVERWRITTEN DATA"
    end
  end

  context "valid model anonymisation" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        # give this anon class a name
        def self.name
          "Employee"
        end

        self.table_name = :employees

        anonymise do
          selectors do
            for_subject(:first_name) do |first_name|
              where(first_name: first_name)
            end

            for_subject(:company_name) do |company_name|
              where(company_name: company_name)
            end
          end

          overwrite do
            ignore :id
            with_strategy StubAnoynmiser, :company_name
            with_strategy(:first_name) { |v, _| v.reverse }
            with_strategy(:last_name) { some_instance_method? ? "yes" : "no" }
            with_strategy "none@example.com", :email_address

            with_strategy "foo", :missing_field

            ignore :phone_number, :onboarded_at
          end
        end

        def some_instance_method?
          true
        end
      end
    end

    let(:model) do
      klass.create!(first_name: "abc", last_name: "foo", company_name: "alpha")
    end

    describe ".anonymise_for!" do
      let!(:model_b) do
        klass.create!(first_name: "matt", last_name: "brown", company_name: "alpha")
      end

      context "selector not found" do
        it "raises an error" do
          expect do
            klass.anonymise_for!(:random, "hello")
          end.to raise_error(Anony::SelectorNotFoundException)
        end
      end

      it "anonymises only the matching models: first_name" do
        results = klass.anonymise_for!(:first_name, model.first_name)
        expect(model.reload.anonymised?).to eq(true)
        expect(model_b.reload.anonymised?).to eq(false)
        expect(results.map(&:record)).to contain_exactly(model)
      end

      it "anonymises only the matching models: company_name" do
        results = klass.anonymise_for!(:company_name, model.company_name)
        expect(model.reload.anonymised?).to be(true)
        expect(model_b.reload.anonymised?).to be(true)
        expect(results.map(&:record)).to contain_exactly(model, model_b)
      end
    end

    describe "#anonymise!" do
      it "anonymises fields" do
        expect { model.anonymise! }.
          to change(model, :company_name).to("OVERWRITTEN DATA").
          and change(model, :first_name).to("cba").
          and change(model, :last_name).to("yes").
          and change(model, :email_address).to("none@example.com")
      end

      it "saves the model" do
        expect(model).to receive(:save!)

        model.anonymise!
      end

      context "ignored fields" do
        it { expect { model.anonymise! }.to_not change(model, :phone_number) }
        it { expect { model.anonymise! }.to_not change(model, :onboarded_at) }
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
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
          destroy
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

  context "preventing anonymisation" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :only_ids

        anonymise do
          destroy
          skip_if { true }
        end
      end
    end

    let!(:model) { klass.create! }

    describe "#anonymise!" do
      it "skips the record" do
        result = model.anonymise!
        expect(result).to be_skipped
      end
    end

    context "when the condition does not match" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          include Anony::Anonymisable

          self.table_name = :only_ids

          anonymise do
            destroy
            skip_if { false }
          end
        end
      end

      describe "#anonymise!" do
        it "destroys the model" do
          expect { model.anonymise! }.to change(klass, :count).by(-1)
        end
      end
    end
  end

  context "without defining a strategy for core fields" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
          overwrite do
            with_strategy StubAnoynmiser, :first_name
          end
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
        expect { model.anonymise! }.to raise_error(Anony::FieldException)
      end
    end
  end

  context "without configuring Anony at all" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :only_ids
      end
    end

    describe "#anonymise!" do
      let(:model) do
        MyUnicornModel = klass
        MyUnicornModel.new
      end

      it "throws an exception" do
        expect { model.anonymise! }.to raise_error(
          ArgumentError, "MyUnicornModel does not have an Anony configuration"
        )
      end
    end

    describe "#selector_for?" do
      it "does not throw an exception" do
        expect { klass.selector_for?(:foo) }.to_not raise_error
      end

      it "returns false" do
        expect(klass.selector_for?(:foo)).to be false
      end
    end
  end

  context "no anonymise block" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        def self.name
          "Employee"
        end

        self.table_name = :employees
      end
    end

    describe "#valid_anonymisation?" do
      it "fails" do
        expect(klass).to_not be_valid_anonymisation
      end
    end

    describe "#selector_for?" do
      it "does not throw an exception" do
        expect { klass.selector_for?(:foo) }.to_not raise_error
      end

      it "returns false" do
        expect(klass.selector_for?(:foo)).to be false
      end
    end

    describe "#anonymise_for!" do
      let(:model) do
        klass.create!(first_name: "abc", last_name: "foo", company_name: "alpha")
      end

      it "throws an exception" do
        expect { klass.anonymise_for!(:first_name, "abc") }.to raise_error(
          ArgumentError, "Employee does not have an Anony configuration"
        )
      end
    end
  end

  context "with an empty anonymise block" do
    it "throws an exception" do
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        anonymise
      end

      expect { klass.anonymise_config.validate! }.
        to raise_error(ArgumentError, "Must specify either :destroy or :overwrite strategy")
    end
  end

  context "when trying to define :overwrite after :destroy" do
    it "throws an exception" do
      expect do
        Class.new(ActiveRecord::Base) do
          include Anony::Anonymisable

          anonymise do
            destroy
            overwrite { nilable :a_field }
          end
        end
      end.to raise_error(
        ArgumentError, "Cannot specify :overwrite when another strategy already defined"
      )
    end
  end

  context "when trying to define :overwrite before :destroy" do
    it "throws an exception" do
      expect do
        Class.new(ActiveRecord::Base) do
          include Anony::Anonymisable

          anonymise do
            overwrite do
              nilable :first_name
            end
            destroy
          end
        end
      end.to raise_error(
        ArgumentError, "Cannot specify :destroy when another strategy already defined"
      )
    end
  end

  context "when anonymised_at column is present" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
          overwrite do
            ignore :id
            hex :first_name
            nilable :last_name
            email :email_address
            phone_number :phone_number
            current_datetime :onboarded_at
            with_strategy(:company_name) { |old| "anonymised-#{old}" }
          end
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
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable
      end

      expect { klass.anonymise { overwrite { ignore :id } } }.to raise_error(
        ArgumentError, "Cannot ignore [:id] (fields already ignored in Anony::Config)"
      )
    end

    it "doesn't warn about ignored :id field" do
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :only_ids

        anonymise { overwrite {} }
      end

      expect(klass).to be_valid_anonymisation
    end
  end

  context "with two models" do
    let(:a_class) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :a_fields

        anonymise do
          overwrite do
            with_strategy StubAnoynmiser, :a_field
          end
        end
      end
    end

    let(:b_class) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :a_fields

        anonymise do
          overwrite do
            with_strategy("foo", :a_field)
          end
        end
      end
    end

    it "models do not leak configuration" do
      #  We had a case where these leaked, so we want to explicitly test it.
      expect(a_class.anonymise_config).to_not eq(b_class.anonymise_config)
    end
  end
end
