# frozen_string_literal: true

require "spec_helper"
require "audited"
require "rails/version"
require "anony/rspec_shared_examples"
require_relative "../../helpers/database"

RSpec.context "ActiveRecord integration using Audited gem" do
  class Employee < ActiveRecord::Base
    include Anony::Anonymisable

    self.table_name = :employees

    audited

    anonymise do
      overwrite do
        hex :first_name
        nilable :last_name
        email :email_address
        phone_number :phone_number
        current_datetime :onboarded_at
        with_strategy(:company_name) { |old| "anonymised-#{old}" }
      end

      audit_log do
        overwrite do
          with_strategy 'REDACTED', :first_name
          nilable :last_name
          email :email_address
          phone_number :phone_number
          current_datetime :onboarded_at
          with_strategy(:company_name) { |old| "anonymised-#{old}" }
        end
      end
    end
  end

  let(:klass) { Employee }

  subject(:instance) do
    klass.create(first_name: "William", last_name: "Gates", company_name: "Microsoft")
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

  it "populates the result audit log changes array with only anonymised fields" do
    result = instance.anonymise!
    expect(result.audit_log_changes.first).to match_array(%i[
      first_name last_name email_address
      phone_number company_name onboarded_at
    ])
  end

  it "sets the anonymised_at column" do
    expect { instance.anonymise! }.
      to change(instance, :anonymised_at).from(nil).to be_within(1).of(Time.now)
  end

  context "with no updates to record" do
    it "should have an audit entry for create" do
      expect(instance.audits.size).to eq(1)
    end
  end

  context "with updates to record" do
    before do
      instance.update!(first_name: "John", last_name: "Smith")
    end

    it "should have an audit entry for create and update" do
      expect(instance.audits.size).to eq(2)
    end

    it "skips creation of audit entry on anonymisation" do
      expect { instance.anonymise! }.to change(instance.audits, :size).by(0)
    end

    it "anonymises create audit entries" do
      expect { instance.anonymise! }.
        to change { instance.audits.first.audited_changes['first_name'] }.from('William').to('REDACTED').
          and change { instance.audits.first.audited_changes['last_name'] }.from('Gates').to(nil)
    end

    it "anonymises update audit entries" do
      expect { instance.anonymise! }.
        to change { instance.audits.last.audited_changes['first_name'].first }.from('William').to('REDACTED').
          and change { instance.audits.last.audited_changes['first_name'].second }.from('John').to('REDACTED').
            and change { instance.audits.last.audited_changes['last_name'].first }.from('Gates').to(nil).
              and change { instance.audits.last.audited_changes['last_name'].second }.from('Smith').to(nil)
    end
  end

  context "with no audit log strategy" do
    class EmployeeWithoutAuditAnonymisation < ActiveRecord::Base
      include Anony::Anonymisable

      self.table_name = :employees

      audited

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

    let(:klass) { EmployeeWithoutAuditAnonymisation }

    context "with updates to record" do
      before do
        instance.update!(first_name: "John", last_name: "Smith")
      end

      it "should have an audit entry for create and update" do
        expect(instance.audits.size).to eq(2)
      end

      it "skips creation of audit entry on anonymisation" do
        expect { instance.anonymise! }.to change(instance.audits, :size).by(0)
      end

      it "leaves create audit entries untouched" do
        expect { instance.anonymise! }.
          to not_change { instance.audits.first.audited_changes['first_name'] }.
            and not_change { instance.audits.first.audited_changes['last_name'] }
      end

      it "leaves update audit entries untouched" do
        expect { instance.anonymise! }.
          to not_change { instance.audits.last.audited_changes['first_name'].first }.
            and not_change { instance.audits.last.audited_changes['first_name'].second }.
              and not_change { instance.audits.last.audited_changes['last_name'].first }.
                and not_change { instance.audits.last.audited_changes['last_name'].second }
      end
    end
  end
end
