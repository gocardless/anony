# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "anonymisable model" do
  it { is_expected.to be_valid_anonymisation }

  it "successfully calls #anonymise!" do
    expect(subject.anonymise!).to be true
  end
end

RSpec.shared_examples "anonymisable model with destruction" do
  it { is_expected.to be_valid_anonymisation }

  it "destroys the model" do
    expect { subject.anonymise! }.to change(described_class, :count).by(-1)
  end
end
