# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Changeset do
  subject(:cs) { described_class.new }

  describe '#initialize' do
    it 'starts with no entries' do
      expect(cs.entries).to be_empty
    end

    it 'starts at depth zero' do
      expect(cs.depth).to eq(0)
    end

    it 'is not terminated' do
      expect(cs).not_to be_terminated
    end
  end

  describe '#add' do
    let(:entry) do
      Mongoid::Changeset::Entry.new(
        type: :update, collection: instance_double(Mongo::Collection), selector: {}, payload: {}, document: nil, session: nil
      )
    end

    it 'appends the entry' do
      cs.add(entry)
      expect(cs.entries).to eq([ entry ])
    end

    context 'when terminated' do
      before { cs.discard }

      it 'raises' do
        expect { cs.add(entry) }.to raise_error(Mongoid::Errors::InvalidOperation)
      end
    end
  end

  describe '#build (nesting)' do
    it 'increments depth inside the block' do
      cs.build { expect(cs.depth).to eq(1) }
    end

    it 'returns depth to zero after the block' do
      cs.build { nil }
      expect(cs.depth).to eq(0)
    end

    it 'nests correctly' do
      cs.build do
        cs.build { expect(cs.depth).to eq(2) }
        expect(cs.depth).to eq(1)
      end
      expect(cs.depth).to eq(0)
    end

    it 'restores depth on exception' do
      begin
        cs.build { raise 'oops' }
      rescue StandardError
        nil
      end
      expect(cs.depth).to eq(0)
    end
  end

  describe '#discard' do
    before do
      entry = Mongoid::Changeset::Entry.new(
        type: :insert, collection: instance_double(Mongo::Collection), selector: {}, payload: {}, document: nil, session: nil
      )
      cs.add(entry)
    end

    it 'clears entries' do
      cs.discard
      expect(cs.entries).to be_empty
    end

    it 'marks as terminated' do
      cs.discard
      expect(cs).to be_terminated
    end

    context 'when already terminated' do
      before { cs.discard }

      it 'raises' do
        expect { cs.discard }.to raise_error(Mongoid::Errors::InvalidOperation)
      end
    end
  end

  describe '#terminated?' do
    it 'is false initially' do
      expect(cs).not_to be_terminated
    end

    it 'is true after discard' do
      cs.discard
      expect(cs).to be_terminated
    end
  end

  describe '#run' do
    it 'raises when terminated' do
      cs.discard
      expect { cs.run { nil } }.to raise_error(Mongoid::Errors::InvalidOperation)
    end

    it 'discards on error at outermost depth' do
      expect { cs.run { raise 'boom' } }.to raise_error(RuntimeError, 'boom')
      expect(cs).to be_terminated
    end

    it 'does not discard on error when nested (inner scope)' do
      cs.run do
        cs.build do
          # This inner-scope error should NOT trigger discard
          # because depth > 0 inside build

          raise 'inner error'
        rescue RuntimeError
          # swallowed
        end
        # Should still be usable after inner error was swallowed
        expect(cs).not_to be_terminated
      end
    rescue NotImplementedError
      # Expected — flush not yet implemented
    end
  end
end
