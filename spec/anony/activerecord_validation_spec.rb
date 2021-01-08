# frozen_string_literal: true

require "spec_helper"
require "anony/rspec_shared_examples"
require_relative "helpers/database"

RSpec.context "ActiveRecord integration" do
  context "when the model has failing validation" do
    subject(:instance) do
      klass.create(first_name: "William", last_name: "Gates", company_name: "Microsoft")
    end

    let(:klass) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        def self.name
          "TestClass"
        end

        self.table_name = :employees

        validates :email_address, presence: true

        anonymise do
          overwrite do
            ignore :id
            ignore :email_address
            hex :first_name
            nilable :last_name
            phone_number :phone_number
            current_datetime :onboarded_at
            with_strategy(:company_name) { |old| "anonymised-#{old}" }
          end
        end
      end
    end

    # rubocop:disable RSpec/ExampleLength
    it "raises a specific error" do
      expect { instance.anonymise! }.
        to raise_error(
          Anony::RecordInvalid,
          "TestClass - raised ActiveRecord::RecordInvalid Validation failed: "\
          "Email address can't be blank",
        )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
