# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/cop_helper"
require "anony/cops/define_deletion_strategy"

RSpec.describe RuboCop::Cop::Lint::DefineDeletionStrategy do
  include CopHelper

  let(:cop) { described_class.new }

  before { inspect_source(source) }

  context "when it isn't a model" do
    let(:source) do
      <<~RUBY
        class Service
        end
      RUBY
    end

    it { expect(cop.offenses).to be_empty }
  end

  context "when it doesn't directly subclass ApplicationRecord" do
    let(:source) do
      <<~RUBY
        module Foo
          class ApplicationRecord; end
        end

        class Service < Foo::ApplicationRecord; end
      RUBY
    end

    it { expect(cop.offenses).to be_empty }
  end

  context "when a model already defines anonymisation rules" do
    let(:source) do
      <<~RUBY
        class Employee < ApplicationRecord
          anonymise do
            hex :first_name
          end
        end
      RUBY
    end

    it { expect(cop.offenses).to be_empty }
  end

  context "when a model does not define anonymisation rules" do
    subject(:offenses) { cop.offenses }

    let(:source) do
      <<~RUBY
        class Employee < ApplicationRecord
        end
      RUBY
    end

    it { expect(offenses.count).to eq(1) }

    it "has the correct name" do
      expect(offenses.first.cop_name).to eq(cop.name)
    end

    it "has the correct message" do
      expect(offenses.first.message).
        to eq("Define .anonymise for Employee, see https://github.com/gocardless/anony/" \
              "blob/#{Anony::VERSION}/README.md for details")
    end
  end
end
