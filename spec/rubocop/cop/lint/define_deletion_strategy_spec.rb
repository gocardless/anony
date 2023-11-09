# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/cop_helper"
require "anony/cops/define_deletion_strategy"

RSpec.describe RuboCop::Cop::Lint::DefineDeletionStrategy do
  include CopHelper

  let(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new(described_class.cop_name => cop_config) }

  let(:cop_config) { {} }

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
            destroy
          end
        end
      RUBY
    end

    it { expect(cop.offenses).to be_empty }
  end

  context "when a model does not define anonymisation rules" do
    subject(:offenses) { cop.offenses }

    shared_examples_for "an offense" do
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

    let(:source) do
      <<~RUBY
        class Employee < ApplicationRecord
        end
      RUBY
    end

    it_behaves_like "an offense"

    context "with a custom model superclasss" do
      let(:cop_config) { { "ModelSuperclass" => "Acme::Record" } }

      let(:source) do
        <<~RUBY
          class Employee < Acme::Record
          end
        RUBY
      end

      it_behaves_like "an offense"
    end
  end

  context "when it uses multiple super classes" do
    subject(:offenses) { cop.offenses }

    let(:cop_config) { { "ModelSuperclass" => ["Acme::Record", "Another::Record"] } }

    context "when models defines anonymisation rules" do
      let(:source) do
        <<~RUBY
          class Employee < Acme::Record
            anonymise do
              destroy
            end
          end

          class Boss < Another::Record
            anonymise do
              destroy
            end
          end
        RUBY
      end

      it { expect(cop.offenses).to be_empty }
    end

    context "when models are missing anonymisation rules" do
      let(:source) do
        <<~RUBY
          class Employee < Another::Record
          end

          class Boss < Another::Record
          end
        RUBY
      end

      it { expect(offenses.count).to eq(2) }

      it "has the correct name" do
        expect(offenses.first.cop_name).to eq(cop.name)
      end
    end
  end
end
