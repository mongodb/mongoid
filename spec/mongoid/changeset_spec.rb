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

  describe '#add_entry' do
    let(:entry) do
      Mongoid::Changeset::Entry.new(
        type: :update, collection: instance_double(Mongo::Collection), selector: {}, payload: {}, document: nil, session: nil
      )
    end

    it 'appends the entry' do
      cs.add_entry(entry)
      expect(cs.entries).to eq([ entry ])
    end

    context 'when terminated' do
      before { cs.discard }

      it 'raises' do
        expect { cs.add_entry(entry) }.to raise_error(Mongoid::Errors::InvalidChangesetOperation)
      end
    end
  end

  describe '#add' do
    let(:coll) { instance_double(Mongo::Collection) }

    it 'constructs an Entry from keyword arguments and appends it' do
      cs.add(type: :update, collection: coll, selector: {}, payload: {}, document: nil, session: nil)
      expect(cs.entries.size).to eq(1)
      expect(cs.entries.first).to be_a(Mongoid::Changeset::Entry)
      expect(cs.entries.first.type).to eq(:update)
    end

    it 'raises when terminated' do
      cs.discard
      expect do
        cs.add(type: :update, collection: coll, selector: {}, payload: {}, document: nil, session: nil)
      end.to raise_error(Mongoid::Errors::InvalidChangesetOperation)
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
      cs.add_entry(entry)
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
        expect { cs.discard }.to raise_error(Mongoid::Errors::InvalidChangesetOperation)
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
      expect { cs.run { nil } }.to raise_error(Mongoid::Errors::InvalidChangesetOperation)
    end

    it 'discards on error at outermost depth' do
      expect { cs.run { raise 'boom' } }.to raise_error(RuntimeError, 'boom')
      expect(cs).to be_terminated
    end

    it 'does not discard on error when nested (inner scope)' do
      cs.run do
        cs.build do
          raise 'inner error'
        rescue RuntimeError
          # swallowed
        end
        expect(cs).not_to be_terminated
      end
    end

    it 'returns the block return value' do
      val = cs.run { 42 }
      expect(val).to eq(42)
    end
  end

  describe 'Mongoid.changeset' do
    after { Mongoid::Threaded.current_changeset = nil }

    it 'creates a new changeset if none is active' do
      cs = nil
      Mongoid.changeset { cs = Mongoid.current_changeset }
      expect(cs).to be_a(Mongoid::Changeset)
    end

    it 'reuses an existing changeset when nested' do
      outer_cs = nil
      inner_cs = nil
      Mongoid.changeset do
        outer_cs = Mongoid.current_changeset
        Mongoid.changeset { inner_cs = Mongoid.current_changeset }
      end
      expect(inner_cs).to equal(outer_cs)
    end

    it 'clears current_changeset after the block exits' do
      Mongoid.changeset { nil }
      expect(Mongoid.current_changeset).to be_nil
    end

    it 'clears current_changeset after a block error' do
      begin
        Mongoid.changeset { raise 'boom' }
      rescue StandardError
        nil
      end
      expect(Mongoid.current_changeset).to be_nil
    end

    it 'exposes Mongoid.current_changeset inside the block' do
      captured = nil
      Mongoid.changeset { captured = Mongoid.current_changeset }
      expect(captured).to be_a(Mongoid::Changeset)
    end
  end

  describe '#flush (unit)' do
    let(:klass) do
      Class.new do
        include Mongoid::Document

        store_in collection: 'changeset_flush_unit_test'
        field :name, type: String
      end
    end

    let(:coll) { instance_double(Mongo::Collection) }
    let(:selector) { { '_id' => BSON::ObjectId.new } }
    let(:payload) { { 'name' => 'Alice' } }

    def make_entry(type:, collection: coll, sel: selector, pay: payload, doc: nil, session: nil)
      Mongoid::Changeset::Entry.new(
        type: type,
        collection: collection,
        selector: sel,
        payload: pay,
        document: doc,
        session: session
      )
    end

    context 'with a single :insert entry' do
      it 'calls insert_one on the collection' do
        allow(coll).to receive(:insert_one)
        cs.add_entry(make_entry(type: :insert))
        cs.flush
        expect(coll).to have_received(:insert_one).with(payload)
      end
    end

    context 'with a single :update entry' do
      it 'calls find(selector).update_one(payload)' do
        view = instance_double(Mongo::Collection::View)
        allow(coll).to receive(:find).with(selector).and_return(view)
        allow(view).to receive(:update_one)
        cs.add_entry(make_entry(type: :update))
        cs.flush
        expect(view).to have_received(:update_one).with(payload)
      end
    end

    context 'with a single :delete entry' do
      it 'calls find(selector).delete_one' do
        view = instance_double(Mongo::Collection::View)
        allow(coll).to receive(:find).with(selector).and_return(view)
        allow(view).to receive(:delete_one)
        cs.add_entry(make_entry(type: :delete, pay: nil))
        cs.flush
        expect(view).to have_received(:delete_one)
      end
    end

    context 'with two consecutive same-collection entries' do
      # Both entries use the same `coll` object; a single Ruby object is equal
      # to itself by both `==` and `equal?`. The implementation uses `==`
      # (value equality), which is what matters in production where
      # `client[name]` returns a fresh Collection object on every call.
      it 'calls bulk_write once' do
        allow(coll).to receive(:bulk_write)
        cs.add_entry(make_entry(type: :insert, pay: { 'name' => 'Alice' }))
        cs.add_entry(make_entry(type: :insert, pay: { 'name' => 'Bob' }))
        cs.flush
        expect(coll).to have_received(:bulk_write).once
      end

      it 'does not call insert_one' do
        allow(coll).to receive(:bulk_write)
        allow(coll).to receive(:insert_one)
        cs.add_entry(make_entry(type: :insert, pay: { 'name' => 'Alice' }))
        cs.add_entry(make_entry(type: :insert, pay: { 'name' => 'Bob' }))
        cs.flush
        expect(coll).not_to have_received(:insert_one)
      end
    end

    context 'with entries from two different collections' do
      let(:coll2) { instance_double(Mongo::Collection) }

      it 'makes two separate driver calls, not a cross-collection bulk_write' do
        allow(coll).to receive(:insert_one)
        allow(coll2).to receive(:insert_one)
        cs.add_entry(make_entry(type: :insert, collection: coll))
        cs.add_entry(make_entry(type: :insert, collection: coll2))
        cs.flush
        expect(coll).to have_received(:insert_one).once
        expect(coll2).to have_received(:insert_one).once
      end

      it 'does not call bulk_write' do
        allow(coll).to receive(:insert_one)
        allow(coll).to receive(:bulk_write)
        allow(coll2).to receive(:insert_one)
        allow(coll2).to receive(:bulk_write)
        cs.add_entry(make_entry(type: :insert, collection: coll))
        cs.add_entry(make_entry(type: :insert, collection: coll2))
        cs.flush
        expect(coll).not_to have_received(:bulk_write)
        expect(coll2).not_to have_received(:bulk_write)
      end
    end

    context 'before_flush callback' do
      it 'fires before the driver call' do
        log = []
        doc = klass.new(name: 'Alice')
        klass.before_flush { log << :callback }
        allow(coll).to receive(:insert_one) { log << :driver }
        cs.add_entry(make_entry(type: :insert, doc: doc))
        cs.flush
        expect(log).to eq(%i[callback driver])
      end
    end

    context 'after_flush callback' do
      it 'fires after the driver call' do
        log = []
        doc = klass.new(name: 'Alice')
        klass.after_flush { log << :callback }
        allow(coll).to receive(:insert_one) { log << :driver }
        cs.add_entry(make_entry(type: :insert, doc: doc))
        cs.flush
        expect(log).to eq(%i[driver callback])
      end
    end

    context 'on driver error' do
      it 'propagates the exception' do
        allow(coll).to receive(:insert_one).and_raise(Mongo::Error::OperationFailure.new('write failed'))
        cs.add_entry(make_entry(type: :insert))
        expect { cs.flush }.to raise_error(Mongo::Error::OperationFailure)
      end

      it 'marks the changeset terminated even when the flush is aborted by an error' do
        allow(coll).to receive(:insert_one).and_raise(Mongo::Error::OperationFailure.new('write failed'))
        cs.add_entry(make_entry(type: :insert))
        begin
          cs.flush
        rescue Mongo::Error::OperationFailure
          nil
        end
        expect(cs).to be_terminated
      end
    end

    context 'document state updates' do
      it 'marks a document with :insert entry as not new_record after flush' do
        doc = klass.new(name: 'Alice')
        expect(doc.new_record?).to be(true)
        allow(coll).to receive(:insert_one)
        cs.add_entry(make_entry(type: :insert, doc: doc))
        cs.flush
        expect(doc.new_record?).to be(false)
      end

      it 'marks a document with :delete entry as destroyed after flush' do
        doc = klass.new(name: 'Alice')
        doc.new_record = false
        view = instance_double(Mongo::Collection::View)
        allow(coll).to receive(:find).with(selector).and_return(view)
        allow(view).to receive(:delete_one)
        cs.add_entry(make_entry(type: :delete, pay: nil, doc: doc))
        cs.flush
        expect(doc.destroyed?).to be(true)
      end
    end
  end
end
