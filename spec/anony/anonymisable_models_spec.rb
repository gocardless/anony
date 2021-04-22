# frozen_string_literal: true

require "spec_helper"
require_relative "helpers/database"

RSpec.describe Anony::AnonymisableModels do
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

  describe "#list" do
    it "returns all models that have been included" do
      expect(klass).to satisfy { |value| subject.list.include?(value) }
    end
  end
end
