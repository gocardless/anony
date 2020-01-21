# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anony::Result do
  let(:field_values) do
    {
      name: "OVERWRITTEN",
      email: "OVERWRITTEN",
    }
  end

  context 'anonymised' do
    let(:result) { described_class.anonymised(field_values) }

    it 'has enumbeable state' do
      expect(result.state).to eq('anonymised')
    end

    it 'responds to .anonymied?' do
      expect(result).to be_anonymised
    end
  end

  context 'deleted' do
    let(:result) { described_class.deleted }

    it 'has enumbeable state' do
      expect(result.state).to eq('deleted')
    end

    it 'responds to .deleted?' do
        expect(result).to be_deleted
    end
  end

  context 'skipped' do
    let(:result) { described_class.skipped }

    it 'has enumbeable state' do
      expect(result.state).to eq('skipped')
    end

    it 'responds to .skipped?' do
      expect(result).to be_skipped
    end
  end

  context 'failed' do
    let(:error) { anything }
    let(:result) { described_class.failed(error) }

    it 'has an error' do
      expect(result.error).to eq(error)
    end

    it 'has enumbeable state' do
      expect(result.state).to eq('failed')
    end

    it 'responds to .failed?' do
      expect(result).to be_failed
    end

    context 'without an error' do
      it 'raises an exception' do
        expect { described_class.failed(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
