# frozen_string_literal: true

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

  create_table :employee_pets do |t|
    t.string :first_name, null: false
    t.string :last_name
    t.string :animal, null: false
    t.datetime :anonymised_at
    t.belongs_to :employee
  end

  create_table :only_ids

  create_table :a_fields, id: false do |t|
    t.string :a_field
  end

  create_table :only_anonymised do |t|
    t.datetime :anonymised_at
  end
end
