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
    t.date :anonymise_after
  end

  create_table :only_ids

  create_table :a_fields, id: false do |t|
    t.string :a_field
  end

  create_table :only_anonymised do |t|
    t.datetime :anonymised_at
  end

  # TODO: Extract into extension gem
  create_table :audits do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :associated_id, :integer
    t.column :associated_type, :string
    t.column :user_id, :integer
    t.column :user_type, :string
    t.column :username, :string
    t.column :action, :string
    t.column :audited_changes, :jsonb
    t.column :version, :integer, :default => 0
    t.column :comment, :string
    t.column :remote_address, :string
    t.column :request_uuid, :string
    t.column :created_at, :datetime
  end
end
