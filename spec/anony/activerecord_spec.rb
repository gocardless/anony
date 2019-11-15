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
    t.datetime :anonymised_at
  end
end

class Employee < ActiveRecord::Base
  include Anony::Anonymisable

  anonymise do
    ignore :id
    hex :first_name
    nilable :last_name
    with_strategy(:company_name) { |old| "anonymised-#{old}" }
  end
end

RSpec.context "ActiveRecord integration" do
  subject(:instance) do
    Employee.create(first_name: "William", last_name: "Gates", company_name: "Microsoft")
  end

  it_behaves_like "anonymisable model"

  it "sets the anonymised_at column" do
    expect { instance.anonymise! }.
      to change(instance, :anonymised_at).from(nil).to be_within(1).of(Time.zone.now)
  end
end
