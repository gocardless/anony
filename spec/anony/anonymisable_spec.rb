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

        self.table_name = :employees

        anonymise do
          ignore :id
          with_strategy StubAnoynmiser, :company_name
          with_strategy(:first_name) { |v, _| v.reverse }
          with_strategy(:last_name) { some_instance_method? ? "yes" : "no" }
          with_strategy "none@example.com", :email_address

          with_strategy "foo", :missing_field

          ignore :phone_number, :onboarded_at
        end

        def some_instance_method?
          true
        end
      end
    end

    let(:model) do
      klass.new(first_name: "abc", last_name: "foo")
    end

    describe "#anonymise!" do
      it "anoynmises fields" do
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

  context "without defining a strategy for core fields" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
          with_strategy StubAnoynmiser, :first_name
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
          Anony::FieldException, "Invalid anonymisation strategy for field(s) [" \
                                 ":id, :last_name, :company_name, :email_address, " \
                                 ":phone_number, :onboarded_at]"
        )
      end
    end
  end

  context "no anonymise block" do
    describe "#valid_anonymisation?" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          include Anony::Anonymisable

          self.table_name = :employees
        end
      end

      it "fails" do
        expect(klass).to_not be_valid_anonymisation
      end
    end
  end

  context "when a strategy is specified after destroy" do
    it "throws an exception" do
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

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
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        anonymise do
          nilable :first_name
        end
      end

      expect { klass.anonymise { destroy } }.to raise_error(
        ArgumentError, "Can't specify destroy and strategies for fields"
      )
    end
  end

  context "when anonymised_at column is present" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
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

      expect { klass.anonymise { ignore :id } }.to raise_error(
        ArgumentError, "Cannot ignore [:id] (fields already ignored in Anony::Config)"
      )
    end

    it "doesn't warn about ignored :id field" do
      klass = Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :only_ids
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
          with_strategy StubAnoynmiser, :a_field
        end
      end
    end

    let(:b_class) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :a_fields

        anonymise do
          with_strategy("foo", :a_field)
        end
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "models do not leak configuration" do
      #  We had a case where these leaked, so we want to explicitly test it.
      expect(a_class.anonymisable_fields).to match(a_field: StubAnoynmiser)
      expect(b_class.anonymisable_fields).to match(a_field: "foo")
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
