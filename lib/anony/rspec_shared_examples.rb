# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "overwritten anonymisable model" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "#anonymise! causes overwrite" do
    result = subject.anonymise!
    expect(result).to be_overwritten
  end
end

RSpec.shared_examples "skipped anonymisable model" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "#anonymise! is skipped" do
    result = subject.anonymise!
    expect(result).to be_skipped
  end

  it "does not change any fields" do
    result = subject.anonymise!
    expect(result.fields).to be_empty
  end
end

RSpec.shared_examples "destroyed anonymisable model" do
  it "has a valid strategy defined" do
    expect(subject.class).to be_valid_anonymisation
  end

  it "destroys the model" do
    expect { subject.anonymise! }.to change(described_class, :count).by(-1)
  end

  it "labels the model as destroyed" do
    result = subject.anonymise!
    expect(result).to be_destroyed
  end
end
