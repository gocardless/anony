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

  it_behaves_like "anonymisable model"

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

  it "correctly populates the result fields hash" do
    result = instance.anonymise!

    expect(result.fields[:first_name]).to match(/[\h\-]{36}/)
    expect(result.fields[:last_name]).to be_nil
    expect(result.fields[:email_address]).to match(/[\h\-]@example.com/)
    expect(result.fields[:phone_number]).to eq("+1 617 555 1294")
    expect(result.fields[:company_name]).to eq("anonymised-Microsoft")
    expect(result.fields[:onboarded_at]).to be_within(1).of(Time.now)
  end

  # rubocop:enable RSpec/ExampleLength

  it "sets the anonymised_at column" do
    expect { instance.anonymise! }.
      to change(instance, :anonymised_at).from(nil).to be_within(1).of(Time.now)
  end
end
