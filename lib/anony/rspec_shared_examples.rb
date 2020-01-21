# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "anonymisable model" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "successfully calls #anonymise!" do
    result = subject.anonymise!
    expect(result).not_to be_failed
  end
end

RSpec.shared_examples "anonymisable model with destruction" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "destroys the model" do
    expect { subject.anonymise! }.to change(described_class, :count).by(-1)
  end

  it "labels the model as destroyed" do
    result = subject.anonymise!
    expect(result).to be_deleted
  end
end
