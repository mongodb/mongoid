# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Atomic::Modifiers do
  let(:modifiers) do
    described_class.new
  end

  context 'when performing multiple operations with similar keys' do
    let(:pushes) do
      { 'addresses.0.locations' => { 'street' => 'Bond St' } }
    end

    let(:similar1) do
      { 'dresses' => { 'color' => 'red' } }
    end

    let(:similar2) do
      { 'ses.0.foo' => { 'baz' => 'qux' } }
    end

    before do
      modifiers.send(operation, pushes)
      modifiers.send(operation, similar1)
      modifiers.send(operation, similar2)
    end

    context 'push' do
      let(:operation) { :push }

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq({ '$push' => {
                                  'addresses.0.locations' => { '$each' => [ { 'street' => 'Bond St' } ] },
                                  'dresses' => { '$each' => [ { 'color' => 'red' } ] },
                                  'ses.0.foo' => { '$each' => [ { 'baz' => 'qux' } ] }
                                } })
      end
    end

    context 'pull' do
      let(:operation) { :pull }

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq({ '$pull' => {
                                  'addresses.0.locations' => { 'street' => 'Bond St' },
                                  'dresses' => { 'color' => 'red' },
                                  'ses.0.foo' => { 'baz' => 'qux' }
                                } })
      end
    end

    context 'pull_all' do
      let(:operation) { :pull_all }

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq({ '$pullAll' => {
                                  'addresses.0.locations' => { 'street' => 'Bond St' },
                                  'dresses' => { 'color' => 'red' },
                                  'ses.0.foo' => { 'baz' => 'qux' }
                                } })
      end
    end

    context 'add_to_set' do
      let(:operation) { :add_to_set }

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq({ '$addToSet' => {
                                  'addresses.0.locations' => { '$each' => { 'street' => 'Bond St' } },
                                  'dresses' => { '$each' => { 'color' => 'red' } },
                                  'ses.0.foo' => { '$each' => { 'baz' => 'qux' } }
                                } })
      end
    end

    context 'set' do
      let(:operation) { :set }

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq({ '$set' => {
                                  'addresses.0.locations' => { 'street' => 'Bond St' },
                                  'dresses' => { 'color' => 'red' },
                                  'ses.0.foo' => { 'baz' => 'qux' }
                                } })
      end
    end

    context 'unset' do
      let(:operation) { :unset }

      let(:pushes) do
        [ :foobar ]
      end

      let(:similar1) do
        [ :foo ]
      end

      let(:similar2) do
        [ :bar ]
      end

      it 'adds all modifiers to top level' do
        expect(modifiers).to eq('$unset' => {
                                  'foobar' => true,
                                  'foo' => true,
                                  'bar' => true
                                })
      end
    end
  end

  context 'when setting and then unsetting an embedded field' do
    let(:book1) { ModifierModels::Book.new(title: 'Slaughterhouse-Five', foreword: ModifierModels::Foreword.new(text: 'Introduction')) }
    let(:book2) { ModifierModels::Book.new(title: "Cat's Cradle") }
    let(:books) { [ book1, book2 ] }
    let(:library) { ModifierModels::Library.create!(name: 'City Library', books: books) }

    let(:new_book) { ModifierModels::Book.new(title: 'Breakfast of Champions', foreword: ModifierModels::Foreword.new(text: 'Foreword')) }

    before do
      # prepare the '$set' operation
      library.assign_attributes(books: [ book1, book2, new_book ])
      # prepare the '$unset' operation
      library.books[0].assign_attributes(foreword: nil)
    end

    it 'does not fail because of the conflict' do
      expect { library.save! }.not_to raise_error

      library.reload
      expect(library.books[0].foreword).to be_nil
      expect(library.books[2].foreword).not_to be_nil
    end
  end

  context 'when assigning embeds_many attributes on a new embedded document' do
    let(:cabinet) do
      ModifierModels::Cabinet.create!
    end

    before do
      cabinet.reload
    end

    context 'when the nested documents are assigned on the built document' do
      before do
        cabinet.build_drawer(matcher: 'all')
        cabinet.drawer.assign_attributes(items: [ { name: 'a' } ])
      end

      it 'saves without conflicting $set paths' do
        expect { cabinet.save! }.not_to raise_error

        cabinet.reload
        expect(cabinet.drawer.matcher).to eq('all')
        expect(cabinet.drawer.items.map(&:name)).to eq([ 'a' ])
      end
    end

    context 'when the nested documents are assigned via the parent' do
      before do
        cabinet.assign_attributes(drawer: { matcher: 'all', items: [ { name: 'a' } ] })
      end

      it 'saves without conflicting $set paths' do
        expect { cabinet.save! }.not_to raise_error

        cabinet.reload
        expect(cabinet.drawer.matcher).to eq('all')
        expect(cabinet.drawer.items.map(&:name)).to eq([ 'a' ])
      end
    end

    context 'when an assigned child has its own embedded collection' do
      let(:item) { ModifierModels::Item.new(name: 'a') }

      before do
        item.assign_attributes(widgets: [ { label: 'w' } ])
        cabinet.build_drawer(matcher: 'all')
        cabinet.drawer.assign_attributes(items: [ item ])
      end

      it 'does not write the child collection to the root document' do
        expect { cabinet.save! }.not_to raise_error

        stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
        expect(stored.keys).to contain_exactly('_id', 'drawer')
        expect(stored['drawer']['items'].first['widgets'].first['label']).to eq('w')
      end
    end
  end
end
