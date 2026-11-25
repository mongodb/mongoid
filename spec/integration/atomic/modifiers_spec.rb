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

  context 'when adding to a set on an existing embedded document and pushing a new one' do
    let(:badges) { Array.new(2) { ModifierModels::Badge.create! } }
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(badges: [ badges[0] ]),
                                       ModifierModels::Player.new(badges: [ badges[0] ])
                                     ])
    end

    before do
      roster.reload
      roster.players.build
      player = roster.players[0]
      player.badge_ids = player.badge_ids + [ badges[1].id ]
      roster.save!
      roster.reload
    end

    it 'applies both operations' do
      expect(roster.players.size).to eq(3)
      expect(roster.players[0].badge_ids).to eq([ badges[0].id, badges[1].id ])
      expect(roster.players[1].badge_ids).to eq([ badges[0].id ])
    end
  end

  context 'when pulling all from an existing embedded document and pushing a new one' do
    let(:badges) { Array.new(2) { ModifierModels::Badge.create! } }
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(badges: badges),
                                       ModifierModels::Player.new
                                     ])
    end

    before do
      roster.reload
      roster.players.build
      player = roster.players[0]
      player.badge_ids = player.badge_ids.drop(1)
      roster.save!
      roster.reload
    end

    it 'applies both operations' do
      expect(roster.players.size).to eq(3)
      expect(roster.players[0].badge_ids).to eq([ badges[1].id ])
    end
  end

  context 'when unsetting a field on an existing embedded document and pushing a new one' do
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(medal: ModifierModels::Medal.new),
                                       ModifierModels::Player.new
                                     ])
    end

    before do
      roster.reload
      roster.players.build
      roster.players[0].assign_attributes(medal: nil)
      roster.save!
      roster.reload
    end

    it 'applies both operations' do
      expect(roster.players.size).to eq(3)
      expect(roster.players[0].medal).to be_nil
    end
  end

  context 'when unsetting an embedded field and pulling a sibling' do
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(medal: ModifierModels::Medal.new),
                                       ModifierModels::Player.new(medal: ModifierModels::Medal.new)
                                     ])
    end

    before do
      roster.reload
      roster.add_atomic_pull(roster.players[0])
      roster.players[1].assign_attributes(medal: nil)
    end

    it 'fails without changing stored data' do
      # $pull shifts array elements, so these operations cannot be safely
      # applied in separate writes; MongoDB rejects them in a single write.
      expect { roster.save! }.to raise_error(Mongo::Error::OperationFailure)

      roster.reload
      expect(roster.players.size).to eq(2)
      expect(roster.players[0].medal).not_to be_nil
      expect(roster.players[1].medal).not_to be_nil
    end
  end

  context 'when changing foreign keys of a remaining nested document after pulling its sibling' do
    let(:badges) { Array.new(2) { ModifierModels::Badge.create! } }
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(badges: [ badges[0] ]),
                                       ModifierModels::Player.new(
                                         badges: [ badges[0] ],
                                         awards: [
                                           ModifierModels::Award.new(name: 'first', badges: [ badges[0] ]),
                                           ModifierModels::Award.new(name: 'second', badges: [ badges[0] ])
                                         ]
                                       )
                                     ])
    end

    before do
      roster.reload
      first_player, second_player = roster.players.to_a
      first_award, second_award = second_player.awards.to_a
      # The change on the first player comes before the nested $pull on the
      # same root. The change on the second award uses its position after
      # the $pull.
      change.call(first_player)
      roster.players_attributes = [
        { id: second_player.id, awards_attributes: [ { id: first_award.id, _destroy: true } ] }
      ]
      change.call(second_award)
    end

    context 'when adding to the foreign keys' do
      let(:change) do
        ->(doc) { doc.badge_ids = doc.badge_ids + [ badges[1].id ] }
      end

      it 'fails without changing stored data' do
        # The $addToSet for the second award would hit the first award if it
        # were applied before the $pull, so it stays in the same update.
        expect { roster.save! }.to raise_error(Mongo::Error::OperationFailure)

        roster.reload
        expect(roster.players[0].badge_ids).to eq([ badges[0].id ])
        expect(roster.players[1].awards.map(&:name)).to eq(%w[first second])
        expect(roster.players[1].awards.map(&:badge_ids)).to eq([ [ badges[0].id ], [ badges[0].id ] ])
      end
    end

    context 'when removing from the foreign keys' do
      let(:change) do
        ->(doc) { doc.badge_ids = [] }
      end

      it 'applies the change to the remaining nested document' do
        roster.save!

        roster.reload
        expect(roster.players[0].badge_ids).to eq([])
        expect(roster.players[1].awards.map(&:name)).to eq([ 'second' ])
        expect(roster.players[1].awards[0].badge_ids).to eq([])
      end
    end
  end

  context 'when renaming a remaining nested document after pulling a preceding sibling and its sibling' do
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(nickname: 'a'),
                                       ModifierModels::Player.new(nickname: 'b'),
                                       ModifierModels::Player.new(
                                         nickname: 'c',
                                         awards: [
                                           ModifierModels::Award.new(name: 'first'),
                                           ModifierModels::Award.new(name: 'second')
                                         ]
                                       )
                                     ])
    end

    before do
      roster.reload
      first_player, second_player, third_player = roster.players.to_a
      first_award, second_award = third_player.awards.to_a
      roster.players_attributes = [
        { id: first_player.id, _destroy: true },
        { id: second_player.id, nickname: 'B' },
        { id: third_player.id, awards_attributes: [
          { id: first_award.id, _destroy: true },
          { id: second_award.id, name: 'SECOND' }
        ] }
      ]
    end

    it 'fails without changing stored data' do
      # Both $pulls stay in the main update. The rename of the second award
      # would hit the first award if it were applied before the nested $pull.
      expect { roster.save! }.to raise_error(Mongo::Error::OperationFailure)

      roster.reload
      expect(roster.players.map(&:nickname)).to eq(%w[a b c])
      expect(roster.players[2].awards.map(&:name)).to eq(%w[first second])
    end
  end

  context 'when adding a nested document and pulling a sibling' do
    let(:roster) do
      ModifierModels::Roster.create!(players: [
                                       ModifierModels::Player.new(nickname: 'a'),
                                       ModifierModels::Player.new(
                                         nickname: 'b',
                                         awards: [ ModifierModels::Award.new(name: 'first') ]
                                       )
                                     ])
    end

    before do
      roster.reload
      first_player, second_player = roster.players.to_a
      second_player.awards.build(name: 'second')
      roster.players_attributes = [ { id: first_player.id, _destroy: true } ]
    end

    it 'applies both operations' do
      roster.save!

      roster.reload
      expect(roster.players.map(&:nickname)).to eq([ 'b' ])
      expect(roster.players[0].awards.map(&:name)).to eq(%w[first second])
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

  context 'when moving an existing embedded document with pending nested changes' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [ { name: 'old' } ])
      cabinet.save!
      cabinet
    end

    let(:item) { cabinet.source.items.first }

    before do
      item.assign_attributes(widgets: [ { label: 'w' } ])
      cabinet.drawer.assign_attributes(items: [ item ])
    end

    it 'does not retain an atomic set at the old path' do
      expect(cabinet.atomic_updates.fetch('$set', {}).keys).to contain_exactly('drawer')
    end

    it 'saves the moved document and replaces the source without duplicates' do
      item_id = item.id
      cabinet.source.assign_attributes(items: [ { name: 'new' } ])
      cabinet.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])
      expect(stored['drawer']['items'].map { |doc| doc['_id'] }).to eq([ item_id ])
      expect(stored['drawer']['items'].first['name']).to eq('old')
      expect(stored['drawer']['items'].first['widgets'].map { |doc| doc['label'] }).to eq([ 'w' ])
    end

    it 'writes subsequent changes to the new parent without a reload' do
      item_id = item.id
      cabinet.source.assign_attributes(items: [ { name: 'new' } ])
      cabinet.save!

      moved = cabinet.drawer.items.first
      moved.widgets.build(label: 'w2')
      cabinet.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])
      expect(stored['source']['items'].first).not_to have_key('widgets')

      moved_item = stored['drawer']['items'].find { |doc| doc['_id'] == item_id }
      expect(moved_item['widgets'].map { |doc| doc['label'] }).to eq(%w[w w2])
    end

    context 'when a validation fails before saving' do
      around do |example|
        validators = ModifierModels::Item.validators.dup
        callbacks = ModifierModels::Item._validate_callbacks.to_a
        example.run
        expect(ModifierModels::Item.validators).to eq(validators)
        expect(ModifierModels::Item._validate_callbacks.to_a).to eq(callbacks)
      end

      it 'keeps the pending move and saves it after the error is fixed' do
        item_id = item.id
        cabinet.source.assign_attributes(items: [ { name: nil } ])
        invalid_item = cabinet.source.items.first
        expect(invalid_item).to receive(:valid?).at_least(:once).and_return(false)
        expect { cabinet.save! }.to raise_error(Mongoid::Errors::Validations)

        stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
        expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'old' ])
        expect(stored['source']['items'].first).not_to have_key('widgets')
        expect(stored).not_to have_key('drawer')

        cabinet.source.assign_attributes(items: [ { name: 'new' } ])
        cabinet.save!

        stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
        expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])
        moved_item = stored['drawer']['items'].find { |doc| doc['_id'] == item_id }
        expect(moved_item['widgets'].map { |doc| doc['label'] }).to eq([ 'w' ])
      end
    end
  end

  context 'when moving an existing embedded document with pending changes deeper in its subtree' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [ { name: 'old', widgets: [ { label: 'w' } ] } ])
      cabinet.save!
      cabinet
    end

    let(:item) { cabinet.source.items.first }
    let(:widget) { item.widgets.first }

    before do
      widget.assign_attributes(parts: [ { code: 'p' } ])
      cabinet.drawer.assign_attributes(items: [ item ])
    end

    it 'saves the moved subtree once and replaces the source' do
      item_id = item.id
      widget_id = widget.id
      cabinet.source.assign_attributes(items: [ { name: 'new' } ])
      cabinet.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])
      expect(stored['source']['items'].first).not_to have_key('widgets')

      expect(stored['drawer']['items'].length).to eq(1)
      moved_item = stored['drawer']['items'].first
      expect(moved_item['_id']).to eq(item_id)
      expect(moved_item['widgets'].length).to eq(1)

      moved_widget = moved_item['widgets'].first
      expect(moved_widget['_id']).to eq(widget_id)
      expect(moved_widget['label']).to eq('w')
      expect(moved_widget['parts'].map { |doc| doc['code'] }).to eq([ 'p' ])
    end
  end

  context 'when moving an existing embedded document through two new parents' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [ { name: 'old', widgets: [ { label: 'w' } ] } ])
      cabinet.save!
      cabinet
    end

    it 'persists the document only in the final parent' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      item = fresh.source.items.first
      item_id = item.id
      widget = item.widgets.first
      widget_id = widget.id

      widget.assign_attributes(parts: [ { code: 'p' } ])
      fresh.drawer.assign_attributes(items: [ item ])
      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ item ])
      fresh.source.assign_attributes(items: [ { name: 'new' } ])

      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])

      locations = %w[source drawer shelf].flat_map do |key|
        Array(stored.dig(key, 'items'))
          .select { |doc| doc['_id'] == item_id }
          .map { key }
      end
      expect(locations).to eq([ 'shelf' ])
      expect(stored.dig('drawer', 'items')).to be_blank
      expect(stored.dig('shelf', 'matcher')).to eq('s')

      moved_widget = stored.dig('shelf', 'items').first['widgets'].first
      expect(moved_widget['_id']).to eq(widget_id)
      expect(moved_widget['label']).to eq('w')
      expect(moved_widget['parts'].map { |doc| doc['code'] }).to eq([ 'p' ])
    end

    it 'keeps other items in an already saved intermediate parent' do
      cabinet.drawer.assign_attributes(items: [ { name: 'sibling' } ])
      cabinet.save!

      fresh = ModifierModels::Cabinet.find(cabinet.id)
      sibling = fresh.drawer.items.first
      item = fresh.source.items.first
      item.widgets.first.assign_attributes(parts: [ { code: 'p' } ])

      fresh.drawer.assign_attributes(items: fresh.drawer.items.to_a + [ item ])
      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ item ])
      fresh.source.assign_attributes(items: [ { name: 'new' } ])

      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'new' ])
      expect(stored.dig('drawer', 'items').map { |doc| doc['_id'] }).to eq([ sibling.id ])
      expect(stored.dig('shelf', 'items').map { |doc| doc['_id'] }).to eq([ item.id ])
      expect(stored.dig('shelf', 'items').first['widgets'].first['parts'].map { |doc| doc['code'] }).to eq([ 'p' ])
    end
  end

  context 'when moving an item out of a saved source and changing a sibling' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [ { name: 'first' }, { name: 'second' } ])
      cabinet.save!
      cabinet
    end

    it 'updates the sibling at its stored position across two saves' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      first, second = fresh.source.items.to_a
      first_id = first.id
      second_id = second.id

      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ first ])
      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored.dig('source', 'items').map { |doc| doc['_id'] }).to eq([ first_id, second_id ])
      expect(stored.dig('source', 'items').map { |doc| doc['name'] }).to eq(%w[first second])
      expect(stored.dig('shelf', 'items').map { |doc| doc['_id'] }).to eq([ first_id ])

      second.name = 'x'
      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored.dig('source', 'items').map { |doc| doc['_id'] }).to eq([ first_id, second_id ])
      expect(stored.dig('source', 'items').map { |doc| doc['name'] }).to eq(%w[first x])
      expect(stored.dig('source', 'items').last['name']).to eq('x')
      expect(stored.dig('shelf', 'items').map { |doc| doc['_id'] }).to eq([ first_id ])
      expect(stored.dig('shelf', 'items').first['name']).to eq('first')
    end

    it 'appends to the source rather than the destination after the move' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      first, second = fresh.source.items.to_a
      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ first ])
      fresh.save!

      added = ModifierModels::Item.new(name: 'third')
      added_items = [ added ]
      fresh.source.items.concat(added_items)

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      aggregate_failures do
        expect(stored.dig('source', 'items').map { |doc| doc['_id'] }).to include(second.id, added.id)
        expect(Array(stored.dig('shelf', 'items')).map { |doc| doc['_id'] }).to eq([ first.id ])
      end
    end

    it 'clears the source without deleting the destination items after the move' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      first = fresh.source.items.first
      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ first ])
      fresh.save!

      fresh.source.items.clear

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      aggregate_failures do
        expect(Array(stored.dig('source', 'items'))).to be_empty
        expect(Array(stored.dig('shelf', 'items')).map { |doc| doc['_id'] }).to eq([ first.id ])
      end
    end
  end

  context 'when a moved item has cached association selectors' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [ { name: 'a', widgets: [ { label: 'w' } ] } ])
      cabinet.save!
      cabinet
    end

    it 'pushes to the new location for nested associations' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      item = fresh.source.items.first
      widget = item.widgets.first

      w1 = ModifierModels::Widget.new(label: 'w1')
      w1_batch = [ w1 ]
      item.widgets.concat(w1_batch)
      p1 = ModifierModels::Part.new(code: 'p1')
      p1_batch = [ p1 ]
      widget.parts.concat(p1_batch)

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      source_item = stored.dig('source', 'items').first
      expect(source_item['widgets'].map { |doc| doc['label'] }).to eq(%w[w w1])
      expect(source_item['widgets'].first['parts'].map { |doc| doc['code'] }).to eq([ 'p1' ])
      expect(w1).to be_persisted
      expect(p1).to be_persisted

      fresh.drawer.assign_attributes(items: [ item ])
      fresh.source.assign_attributes(items: [ { name: 'n' } ])
      fresh.save!

      w2 = ModifierModels::Widget.new(label: 'w2')
      w2_batch = [ w2 ]
      item.widgets.concat(w2_batch)
      p2 = ModifierModels::Part.new(code: 'p2')
      p2_batch = [ p2 ]
      widget.parts.concat(p2_batch)

      expect(w2).to be_persisted
      expect(p2).to be_persisted

      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored['source']['items'].map { |doc| doc['name'] }).to eq([ 'n' ])
      drawer_item = stored.dig('drawer', 'items').first
      expect(drawer_item['widgets'].map { |doc| doc['label'] }).to eq(%w[w w1 w2])
      expect(drawer_item['widgets'].map { |doc| doc['_id'] }.uniq.length).to eq(3)
      expect(drawer_item['widgets'].first['parts'].map { |doc| doc['code'] }).to eq(%w[p1 p2])
      expect(drawer_item['widgets'].first['parts'].map { |doc| doc['_id'] }.uniq.length).to eq(2)
    end
  end

  context 'when a part moves out of a subtree inside a new parent' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [
                             { name: 'a', widgets: [ { label: 'w', parts: [ { code: 'p' } ] } ] },
                             { name: 'b', widgets: [ { label: 'v' } ] }
                           ])
      cabinet.save!
      cabinet
    end

    it 'does not serialize the moved part into the new parent subtree' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      item = fresh.source.items[0]
      destination = fresh.source.items[1].widgets.first
      part = item.widgets.first.parts.first
      part_id = part.id

      fresh.drawer.assign_attributes(items: [ item ])
      destination.parts << part
      fresh.save!
      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored.dig('source', 'items', 1, 'widgets', 0, 'parts').map { |doc| doc['_id'] }).to eq([ part_id ])
      expect(Array(stored.dig('drawer', 'items', 0, 'widgets', 0, 'parts'))).to be_empty
      expect(part).to be_persisted
    end

    it 'does not serialize the moved part into another new parent subtree' do
      fresh = ModifierModels::Cabinet.find(cabinet.id)
      item = fresh.source.items[0]
      destination = fresh.source.items[1].widgets.first
      part = item.widgets.first.parts.first
      part_id = part.id

      fresh.build_shelf(matcher: 's')
      fresh.shelf.assign_attributes(items: [ item ])
      destination.parts << part
      fresh.save!
      fresh.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      expect(stored.dig('source', 'items', 1, 'widgets', 0, 'parts').map { |doc| doc['_id'] }).to eq([ part_id ])
      expect(Array(stored.dig('shelf', 'items', 0, 'widgets', 0, 'parts'))).to be_empty
      expect(part).to be_persisted
    end
  end

  context 'when clearing an association in a moved subtree' do
    let(:cabinet) do
      cabinet = ModifierModels::Cabinet.find(ModifierModels::Cabinet.create!.id)
      cabinet.build_source(items: [
                             { name: 'a', widgets: [ { label: 'w', parts: [ { code: 'p' }, { code: 'q' } ] } ] }
                           ])
      cabinet.save!
      ModifierModels::Cabinet.find(cabinet.id)
    end

    it 'clears the removal flags after saving the moved subtree' do
      item = cabinet.source.items.first
      widget = item.widgets.first
      first, second = widget.parts.to_a

      cabinet.drawer.assign_attributes(items: [ item ])
      widget.assign_attributes(parts: [])
      cabinet.source.assign_attributes(items: [ { name: 'new' } ])
      cabinet.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      aggregate_failures do
        expect(stored.dig('source', 'items').map { |doc| doc['name'] }).to eq([ 'new' ])
        expect(Array(stored.dig('drawer', 'items', 0, 'widgets', 0, 'parts'))).to be_empty
        expect(first).to be_destroyed
        expect(first).not_to be_persisted
        expect(first).not_to be_marked_for_destruction
        expect(second).to be_destroyed
        expect(second).not_to be_persisted
        expect(second).not_to be_marked_for_destruction
      end
    end

    it 'marks each nested document removed through attributes as destroyed' do
      item = cabinet.source.items.first
      widget = item.widgets.first
      first, second = widget.parts.to_a

      cabinet.drawer.assign_attributes(items: [ item ])
      widget.assign_attributes(parts_attributes: [
                                 { id: first.id, _destroy: true },
                                 { id: second.id, _destroy: true }
                               ])
      cabinet.source.assign_attributes(items: [ { name: 'new' } ])
      cabinet.save!

      stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
      aggregate_failures do
        expect(stored.dig('source', 'items').map { |doc| doc['name'] }).to eq([ 'new' ])
        expect(Array(stored.dig('drawer', 'items', 0, 'widgets', 0, 'parts'))).to be_empty
        expect(first).to be_destroyed
        expect(first).not_to be_persisted
        expect(first).not_to be_marked_for_destruction
        expect(second).to be_destroyed
        expect(second).not_to be_persisted
        expect(second).not_to be_marked_for_destruction
      end
    end

    context 'when validation fails before saving' do
      around do |example|
        validators = ModifierModels::Item.validators.dup
        callbacks = ModifierModels::Item._validate_callbacks.to_a
        example.run
        expect(ModifierModels::Item.validators).to eq(validators)
        expect(ModifierModels::Item._validate_callbacks.to_a).to eq(callbacks)
      end

      it 'keeps the removal pending until a successful save' do
        item = cabinet.source.items.first
        widget = item.widgets.first
        removed = widget.parts.first

        cabinet.drawer.assign_attributes(items: [ item ])
        widget.assign_attributes(parts: [])
        cabinet.source.assign_attributes(items: [ { name: nil } ])

        invalid_item = cabinet.source.items.first
        expect(invalid_item).to receive(:valid?).at_least(:once).and_return(false)
        expect { cabinet.save! }.to raise_error(Mongoid::Errors::Validations)
        expect(removed).to be_marked_for_destruction
        stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
        expect(stored).not_to have_key('drawer')
        expect(stored.dig('source', 'items', 0, 'widgets', 0, 'parts').map { |doc| doc['code'] }).to eq(%w[p q])

        cabinet.source.assign_attributes(items: [ { name: 'new' } ])
        cabinet.save!

        expect(removed).to be_destroyed
        expect(removed).not_to be_persisted
        expect(removed).not_to be_marked_for_destruction
        stored = ModifierModels::Cabinet.collection.find(_id: cabinet.id).first
        expect(Array(stored.dig('drawer', 'items', 0, 'widgets', 0, 'parts'))).to be_empty
      end
    end
  end
end
