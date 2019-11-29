# frozen_string_literal: true

require "spec_helper"

RSpec.describe "current_datetime strategy" do # rubocop:disable RSpec/DescribeClass
  subject(:result) do
    model.instance_exec(&Anony::Strategies[:current_datetime])
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      include Anony::Anonymisable

      self.table_name = :employees
    end
  end

  let(:model) { klass.new }

  let(:value) { "old value" }

  it { is_expected.to be_within(1).of(Time.now) }
end
