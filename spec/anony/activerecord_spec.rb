# frozen_string_literal: true

require "spec_helper"
require "anony/rspec_shared_examples"

require "sqlite3"
require "active_record"

# Connect to an in-memory sqlite3 database
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Suppress STDOUT schema creation
ActiveRecord::Schema.verbose = false

# Define a minimal database schema
ActiveRecord::Schema.define do
  create_table :employees do |t|
    t.string :first_name, null: false
    t.string :last_name
    t.string :company_name, null: false
    t.string :email_address
    t.string :phone_number
    t.datetime :onboarded_at
    t.datetime :anonymised_at
  end
end

class Employee < ActiveRecord::Base
  include Anony::Anonymisable

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

RSpec.context "ActiveRecord integration" do
  subject(:instance) do
    Employee.create(first_name: "William", last_name: "Gates", company_name: "Microsoft")
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
      and change(instance, :onboarded_at).to be_within(1).of(Time.zone.now)
  end
  # rubocop:enable RSpec/ExampleLength

  it "sets the anonymised_at column" do
    expect { instance.anonymise! }.
      to change(instance, :anonymised_at).from(nil).to be_within(1).of(Time.zone.now)
  end
end
