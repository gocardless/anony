# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "anonymisable model" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "successfully calls #anonymise!" do
    expect(subject.anonymise!).to be true
  end
end

RSpec.shared_examples "anonymisable model with destruction" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "destroys the model" do
    expect { subject.anonymise! }.to change(described_class, :count).by(-1)
  end
end
