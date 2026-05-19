# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Persistable do
  class PersistableSpecTestException < StandardError; end

  describe '#atomically' do
    let!(:doc) { Band.create!(member_count: 0, likes: 60, origin: 'London') }

    it 'applies all operations when the block succeeds' do
      doc.atomically do |d|
        d.inc(member_count: 10)
        d.set(name: 'Placebo')
      end
      doc.reload
      expect(doc.member_count).to eq(10)
      expect(doc.name).to eq('Placebo')
    end

    it 'does not persist any operations when the block raises' do
      expect do
        doc.atomically do |d|
          d.inc(member_count: 10)
          raise 'abort'
        end
      end.to raise_error(RuntimeError, 'abort')
      expect(doc.reload.member_count).to eq(0)
    end

    it 'nests correctly: inner atomically merges into outer' do
      doc.atomically do |d|
        d.inc(member_count: 5)
        d.atomically do |d2|
          d2.inc(member_count: 5)
        end
      end
      expect(doc.reload.member_count).to eq(10)
    end

    it 'with join_context: false persists independently even when outer raises' do
      begin
        doc.atomically do |d|
          d.set(origin: 'Paris')
          d.atomically(join_context: false) do |d2|
            d2.inc(member_count: 10)
          end
          d.inc(likes: 1)
          raise 'abort'
        end
      rescue RuntimeError
        # expected
      end
      doc.reload
      expect(doc.member_count).to eq(10)
      expect(doc.origin).to eq('London')
      expect(doc.likes).to eq(60)
    end

    it 'returns true when given no block' do
      expect(doc.atomically).to be true
    end

    context 'when the block has no operations' do
      it 'does not update the document' do
        doc.atomically {}
        expect(doc.reload.origin).to eq('London')
      end
    end

    it 'persists multiple same-type operations (two inc calls)' do
      doc.atomically do |d|
        d.inc(member_count: 3)
        d.inc(member_count: 7)
      end
      expect(doc.reload.member_count).to eq(10)
    end

    it 'with join_context: false and no enclosing context, still persists' do
      doc.atomically(join_context: false) do |d|
        d.inc(member_count: 5)
      end
      expect(doc.reload.member_count).to eq(5)
    end

    it 'with join_context: false emits a deprecation warning' do
      Mongoid::Warnings.instance_variable_set(:@join_context_false_deprecated, nil)
      expect(Mongoid.logger).to receive(:warn).with(/deprecated/)
      doc.atomically(join_context: false) { |d| d.inc(member_count: 1) }
    end
  end

  describe '#fail_due_to_valiation!' do
    let(:document) do
      Band.new
    end

    it 'raises the validation error' do
      expect do
        document.fail_due_to_validation!
      end.to raise_error(Mongoid::Errors::Validations)
    end
  end

  describe '#fail_due_to_callback!' do
    let(:document) do
      Band.new
    end

    it 'raises the callback error' do
      expect do
        document.fail_due_to_callback!(:save!)
      end.to raise_error(Mongoid::Errors::Callback)
    end
  end
end
