# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/cop_helper"
require_relative "../../../config/cops/define_deletion_strategy"

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
    let(:source) do
      <<~RUBY
        class Employee < ApplicationRecord
        end
      RUBY
    end

    it "registers an offense" do
      expect(cop.offenses.count).to eq(1)
      expect(cop.offenses.first.cop_name).to eq(cop.name)
      expect(cop.offenses.first.message).
        to eq("Define .anonymise for Employee, see ./lib/anony/README.md for details")
    end
  end
end
