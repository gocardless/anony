# frozen_string_literal: true

require "spec_helper"
require "anony/rspec_shared_examples"
require_relative "helpers/database"

RSpec.context "ActiveRecord integration" do
  subject(:instance) do
    klass.create(first_name: "William", last_name: "Gates", company_name: "Microsoft")
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      include Anony::Anonymisable

      self.table_name = :employees

      anonymise do
        overwrite do
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

  it_behaves_like "overwritten anonymisable model"

  # rubocop:disable RSpec/ExampleLength
  it "applies the correct changes to each column" do
    expect { instance.anonymise! }.
      to change(instance, :first_name).to(/[\h\-]{36}/).
      and change(instance, :last_name).to(nil).
      and change(instance, :email_address).to(/[\h\-]@example.com/).
      and change(instance, :phone_number).to("+1 617 555 1294").
      and change(instance, :company_name).to("anonymised-Microsoft").
      and change(instance, :onboarded_at).to be_within(1).of(Time.now)
  end
  # rubocop:enable RSpec/ExampleLength

  it "populates the result fields hash with only anonymised fields" do
    result = instance.anonymise!
    expect(result.fields).to match_array(%i[
      first_name last_name email_address
      phone_number company_name onboarded_at
    ])
  end

  it "sets the anonymised_at column" do
    expect { instance.anonymise! }.
      to change(instance, :anonymised_at).from(nil).to be_within(1).of(Time.now)
  end

  context "with ignored_by_default set in Anony::Config" do
    around do |example|
      begin
        original_value = Anony::Config.ignored_by_default
        Anony::Config.ignored_by_default = true
        example.call
      ensure
        Anony::Config.ignored_by_default = original_value
      end
    end

    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise do
          overwrite do
            hex :first_name
            ignore :last_name
          end
        end
      end
    end

    it "should be valid configuration" do
      expect(klass).to be_valid_anonymisation
    end

    it "should not complain about unhandled fields" do
      expect { instance.anonymise! }.to_not raise_error
    end

    it "should anonymise specified fields" do
      expect { instance.anonymise! }.to change(instance, :first_name)
    end

    it "should not anonymise unhandled fields" do
      expect { instance.anonymise! }.to_not change(instance, :company_name)
    end
  end
end
