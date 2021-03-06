# frozen_string_literal: true

require "spec_helper"
require "anony/rspec_shared_examples"
require_relative "helpers/database"

RSpec.describe "RSpec shared examples" do
  subject do
    klass = Class.new(ActiveRecord::Base) do
      include Anony::Anonymisable

      self.table_name = :a_fields

      anonymise do
        overwrite do
          hex :a_field
        end
      end
    end

    klass.new
  end

  it_behaves_like "overwritten anonymisable model"

  context "with destruction" do
    let(:described_class) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :employees

        anonymise { destroy }
      end
    end

    it_behaves_like "destroyed anonymisable model" do
      subject! { described_class.create!(first_name: "foo", company_name: "bar") }
    end
  end

  context "with skipping" do
    let(:described_class) do
      Class.new(ActiveRecord::Base) do
        include Anony::Anonymisable

        self.table_name = :a_fields

        anonymise do
          skip_if { true }
          overwrite do
            hex :a_field
          end
        end
      end
    end

    it_behaves_like "skipped anonymisable model" do
      subject! { described_class.create!(a_field: "foo") }
    end
  end
end
