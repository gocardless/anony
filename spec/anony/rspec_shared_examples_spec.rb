# frozen_string_literal: true

require "spec_helper"
require "anony/rspec_shared_examples"

RSpec.describe "RSpec shared examples" do
  subject do
    klass = Class.new do
      include Anony::Anonymisable

      attr_accessor :a_field

      anonymise do
        hex :a_field
      end

      def self.column_names
        %w[a_field]
      end

      alias_method :read_attribute, :send
      def write_attribute(field, value)
        send("#{field}=", value)
      end

      def save!
        true
      end
    end

    klass.new
  end

  it_behaves_like "anonymisable model"

  context "with destruction" do
    let(:described_class) do
      Class.new do
        include Anony::Anonymisable

        anonymise { destroy }

        def self.column_names
          %w[a_field]
        end

        alias_method :read_attribute, :send
        def write_attribute(field, value)
          send("#{field}=", value)
        end

        @count = 1
        def self.count # rubocop:disable Style/TrivialAccessors
          @count
        end

        def destroy!
          self.class.instance_eval { @count -= 1 }
        end
      end
    end

    it_behaves_like "anonymisable model with destruction" do
      subject { described_class.new }
    end
  end
end
