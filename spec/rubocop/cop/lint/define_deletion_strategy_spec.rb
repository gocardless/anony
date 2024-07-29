# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "spec_helper"
require "anony/cops/define_deletion_strategy"

RSpec.describe RuboCop::Cop::Lint::DefineDeletionStrategy, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:config) { RuboCop::Config.new(described_class.cop_name => cop_config) }
  let(:cop_config) { {} }

  let(:error_msg) do
    "Define .anonymise for %s, see https://github.com/gocardless/anony/" \
      "blob/#{Anony::VERSION}/README.md for details"
  end

  context "when it isn't a model" do
    it "doesn't register an offense" do
      expect_no_offenses(<<~RUBY)
        class Service
        end
      RUBY
    end
  end

  context "when it doesn't directly subclass ApplicationRecord" do
    it "doesn't register an offense" do
      expect_no_offenses(<<~RUBY)
        module Foo
          class ApplicationRecord; end
        end

        class Service < Foo::ApplicationRecord; end
      RUBY
    end
  end

  context "when a model already defines anonymisation rules" do
    it "doesn't register an offense" do
      expect_no_offenses(<<~RUBY)
        class Employee < ApplicationRecord
          anonymise do
            destroy
          end
        end
      RUBY
    end
  end

  context "when a model does not define anonymisation rules" do
    subject(:offenses) { cop.offenses }

    it "registers an offense" do
      expect_offense(<<~RUBY)
        class Employee < ApplicationRecord
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{error_msg % 'Employee'}
        end
      RUBY
    end

    context "with a custom model superclass" do
      let(:cop_config) { { "ModelSuperclass" => "Acme::Record" } }

      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Employee < Acme::Record
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{error_msg % 'Employee'}
          end
        RUBY
      end
    end
  end

  context "when it uses multiple superclasses" do
    subject(:offenses) { cop.offenses }

    let(:cop_config) { { "ModelSuperclass" => %w[Acme::Record Another::Record] } }

    context "when models defines anonymisation rules" do
      it "doesn't register an offense" do
        expect_no_offenses(<<~RUBY)
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
    end

    context "when models are missing anonymisation rules" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Employee < Another::Record
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{error_msg % 'Employee'}
          end

          class Boss < Another::Record
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{error_msg % 'Boss'}
          end
        RUBY
      end
    end
  end
end
