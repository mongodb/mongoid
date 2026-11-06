# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Attributes::Readonly do
  before do
    Person.attr_readonly(*attributes)
  end

  after do
    Person.readonly_attributes.reject! do |a|
      [ attributes ].flatten.include?(a.to_sym) ||
        [ attributes ].flatten.include?(Person.aliased_fields.key(a).to_sym)
    end
  end

  describe '.attr_readonly' do
    context 'when providing a single field' do
      let(:attributes) do
        :title
      end

      it 'adds the field to readonly attributes' do
        expect(Person.readonly_attributes.to_a).to include('title')
      end
    end

    context 'when providing a field alias' do
      let(:attributes) do
        :aliased_timestamp
      end

      it 'adds the database field name to readonly attributes' do
        expect(Person.readonly_attributes.to_a).to include('at')
      end
    end

    context 'when providing multiple fields' do
      let(:attributes) do
        %i[title terms]
      end

      it 'adds the fields to readonly attributes' do
        expect(Person.readonly_attributes.to_a).to include('title', 'terms')
      end
    end

    context 'when creating a new document with a readonly field' do
      let(:attributes) do
        %i[title terms aliased_timestamp]
      end

      let(:person) do
        Person.create!(title: 'sir', terms: true, aliased_timestamp: Time.at(42))
      end

      it 'sets the first readonly value' do
        expect(person.title).to eq('sir')
      end

      it 'sets the second readonly value' do
        expect(person.terms).to be true
      end

      it 'sets the third readonly value' do
        expect(person.aliased_timestamp).to eq(Time.at(42))
      end

      it 'persists the first readonly value' do
        expect(person.reload.title).to eq('sir')
      end

      it 'persists the second readonly value' do
        expect(person.reload.terms).to be true
      end

      it 'persists the third readonly value' do
        expect(person.reload.aliased_timestamp).to eq(Time.at(42))
      end

      it 'reports the readonly value as a saved change' do
        expect(person.previous_changes['title']).to eq([ nil, 'sir' ])
        expect(person.saved_change_to_attribute('title')).to eq([ nil, 'sir' ])
        expect(person.saved_change_to_attribute?(:title)).to be true
        expect(person.title_previously_changed?).to be true
      end

      it 'reports the saved change for an aliased readonly field' do
        expect(person.previous_changes['at']).to eq([ nil, Time.at(42) ])
        expect(person.saved_change_to_attribute?(:aliased_timestamp)).to be true
      end

      it 'does not persist a later change to the readonly field' do
        person.title = 'mr'
        person.score = 1
        person.save!

        expect(person.previous_changes).not_to have_key('title')
        expect(person.previous_changes).to have_key('score')

        expect(person.reload.title).to eq('sir')
        expect(person.reload.score).to eq(1)
      end
    end

    context 'when updating an existing readonly field' do
      let(:attributes) do
        %i[title terms score aliased_timestamp]
      end

      let(:person) do
        Person.create!(title: 'sir', terms: true, score: 1, aliased_timestamp: Time.at(42))
      end

      context 'when updating via the setter' do
        it 'does not update the first field' do
          person.title = 'mr'
          person.save!
          expect(person.reload.title).to eq('sir')
        end

        it 'does not update the second field' do
          person.aliased_timestamp = Time.at(43)
          person.save!
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context 'when updating via inc' do
        context 'with single field operation' do
          it 'updates the field' do
            person.inc(score: 1)
            person.save!
            expect(person.reload.score).to eq(2)
          end
        end

        context 'with multiple fields operation' do
          it 'updates the fields' do
            person.inc(score: 1, age: 1)
            person.save!
            expect(person.reload.score).to eq(2)
            expect(person.reload.age).to eq(101)
          end
        end
      end

      context 'when updating via bit' do
        context 'with single field operation' do
          it 'does the update' do
            person.bit(score: { or: 13 })
            person.save!
            expect(person.reload.score).to eq(13)
          end
        end

        context 'with multiple fields operation' do
          it 'updates the attribute' do
            person.bit(age: { and: 13 }, score: { or: 13 })
            person.save!
            expect(person.reload.score).to eq(13)
            expect(person.reload.age).to eq(4)
          end
        end
      end

      context 'when updating via []=' do
        it 'does not update the first field' do
          person[:title] = 'mr'
          person.save!
          expect(person.reload.title).to eq('sir')
        end

        it 'does not update the second field' do
          person[:aliased_timestamp] = Time.at(43)
          person.save!
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context 'when updating via write_attribute' do
        it 'does not update the first field' do
          person.write_attribute(:title, 'mr')
          person.save!
          expect(person.reload.title).to eq('sir')
        end

        it 'does not update the second field' do
          person.write_attribute(:aliased_timestamp, Time.at(43))
          person.save!
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context 'when updating via update_attributes' do
        it 'does not update the first field' do
          person.update_attributes!(title: 'mr', aliased_timestamp: Time.at(43))
          person.save!
          expect(person.reload.title).to eq('sir')
        end

        it 'does not update the second field' do
          person.update_attributes!(title: 'mr', aliased_timestamp: Time.at(43))
          person.save!
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context 'when updating via update_attributes!' do
        it 'does not update the first field' do
          person.update_attributes!(title: 'mr', aliased_timestamp: Time.at(43))
          person.save!
          expect(person.reload.title).to eq('sir')
        end

        it 'does not update the second field' do
          person.update_attributes!(title: 'mr', aliased_timestamp: Time.at(43))
          person.save!
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context 'when updating via update_attribute' do
        it 'raises an error' do
          expect do
            person.update_attribute(:title, 'mr')
          end.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end
      end

      context 'when updating via remove_attribute' do
        it 'raises an error' do
          expect do
            person.remove_attribute(:title)
          end.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end
      end
    end

    context 'when modifying a readonly field in place' do
      let(:attributes) do
        %i[map aliases array]
      end

      let(:person) do
        Person.create!(map: { 'enabled' => false }, aliases: [ 'original' ], array: [ 'original' ], title: 'old')
      end

      it 'does not persist changes to a readonly hash' do
        person.map['enabled'] = true
        person.save!

        expect(person.reload.map).to eq('enabled' => false)
      end

      it 'does not mark the document as changed' do
        person.map['enabled'] = true

        expect(person).not_to be_changed
      end

      it 'does not mark an aliased readonly field as changed' do
        person.array << 'added'

        expect(person).not_to be_changed
      end

      it 'allows in-place changes before the document is created' do
        new_person = Person.new(map: { 'enabled' => false })
        new_person.map['enabled'] = true
        new_person.save!

        expect(new_person.reload.map).to eq('enabled' => true)
      end

      it 'does not report the ignored change as saved' do
        person.map['enabled'] = true
        person.title = 'new'
        person.save!

        expect(person.previous_changes).not_to have_key('map')
        expect(person.previous_changes).to have_key('title')
      end

      it 'does not update timestamps for an ignored change' do
        model = test_model do
          include Mongoid::Timestamps

          field :settings, type: Hash
          attr_readonly :settings
        end
        document = Timecop.freeze(Time.utc(2020, 1, 1)) do
          model.create!(settings: { 'enabled' => false })
        end

        document.settings['enabled'] = true
        Timecop.freeze(Time.utc(2020, 1, 2)) { document.save! }

        expect(document.reload.updated_at).to eq(Time.utc(2020, 1, 1))
      end

      it 'does not persist changes made through attributes' do
        person.map
        person.attributes['map']['enabled'] = true
        person.save!

        expect(person.reload.map).to eq('enabled' => false)
      end

      it 'resets an in-place change to a readonly hash' do
        person.map['enabled'] = true
        person.reset_map!

        expect(person.map).to eq('enabled' => false)
        expect(person).not_to be_changed
      end

      context 'when a tracked field becomes readonly' do
        let(:model) do
          test_model do
            include Mongoid::Timestamps

            field :settings, type: Hash
            field :title
          end
        end

        let(:document) do
          Timecop.freeze(Time.utc(2020, 1, 1)) do
            model.create!(settings: { 'enabled' => false }, title: 'old')
          end
        end

        before do
          document.settings['enabled'] = true
          model.attr_readonly :settings
        end

        it 'does not persist the ignored change' do
          document.save!

          expect(document.reload.settings).to eq('enabled' => false)
        end

        it 'does not report the ignored change as dirty' do
          expect(document).not_to be_changed
          expect(document.changes).not_to have_key('settings')
        end

        it 'does not report the readonly field as changed' do
          expect(document.settings_changed?).to be false
        end

        it 'does not report the ignored change as saved' do
          document.title = 'new'
          document.save!

          expect(document.previous_changes).not_to have_key('settings')
          expect(document.saved_change_to_attribute?(:settings)).to be false
          expect(document.previous_changes).to have_key('title')
        end

        it 'does not update timestamps for the ignored change' do
          Timecop.freeze(Time.utc(2020, 1, 2)) { document.save! }

          expect(document.reload.updated_at).to eq(Time.utc(2020, 1, 1))
        end
      end

      it 'does not persist changes to a readonly array' do
        person.aliases << 'added'
        person.save!

        expect(person.reload.aliases).to eq([ 'original' ])
      end

      it 'does not persist changes to an aliased readonly field' do
        person.array << 'added'
        person.save!

        expect(person.reload.array).to eq([ 'original' ])
      end

      it 'persists changes to other fields' do
        person.map['enabled'] = true
        person.title = 'new'
        person.save!

        expect(person.reload.map).to eq('enabled' => false)
        expect(person.title).to eq('new')
      end

      it 'still allows atomic set on a readonly field' do
        person.set('map.enabled' => true)

        expect(person.reload.map).to eq('enabled' => true)
      end

      it 'still allows atomic unset on a readonly field' do
        person.unset('map.enabled')

        expect(person.reload.map).to eq({})
      end

      context 'when an atomic array update fails' do
        it 'restores the readonly array in memory and in the database' do
          expect do
            person.atomically do
              person.push(aliases: 'added')
              raise 'abort'
            end
          end.to raise_error('abort')

          expect(Person.collection.find(_id: person.id).first['aliases']).to eq([ 'original' ])
          expect(person.aliases).to eq([ 'original' ])
        end

        it 'still allows a successful atomic update' do
          person.atomically { person.push(aliases: 'added') }

          expect(person.reload.aliases).to eq(%w[original added])
        end
      end
    end

    context 'when an embedded document has a readonly hash' do
      let(:attributes) do
        :title
      end

      let(:person) do
        Person.create!(addresses: [ { street: 'Main', map: { 'enabled' => false } } ])
      end

      around do |example|
        original = Address.readonly_attributes
        Address.attr_readonly :map
        example.run
      ensure
        Address.readonly_attributes = original
      end

      it 'allows the initial value to be saved' do
        expect(person.reload.addresses.first.map).to eq('enabled' => false)
      end

      it 'ignores in-place changes when saving the parent' do
        person.addresses.first.map['enabled'] = true
        person.save!

        expect(person.reload.addresses.first.map).to eq('enabled' => false)
      end

      it 'ignores in-place changes when saving the embedded document' do
        address = person.addresses.first
        address.map['enabled'] = true
        address.save!

        expect(person.reload.addresses.first.map).to eq('enabled' => false)
      end

      it 'allows an initial value when adding a new embedded document' do
        person.addresses.build(street: 'Second', map: { 'enabled' => true })
        person.save!

        expect(person.reload.addresses.last.map).to eq('enabled' => true)
      end

      it 'reports the initial value as a saved change' do
        address = person.addresses.first

        expect(address.previous_changes['map']).to eq([ nil, { 'enabled' => false } ])
        expect(address.saved_change_to_attribute?(:map)).to be true
      end
    end

    context 'when a persisted root document is converted with becomes' do
      let(:attributes) do
        :title
      end

      let(:model) do
        test_model do
          field :settings, type: Hash
          attr_readonly :settings
        end
      end

      let(:original) do
        model.create!(settings: { 'enabled' => false })
      end

      it 'does not persist an in-place change to the readonly field of the became root document' do
        became = original.becomes(model)
        became.settings['enabled'] = true
        became.save!

        expect(model.collection.find(_id: original.id).first['settings']).to eq('enabled' => false)
      end
    end

    context 'when a persisted document is converted to another class with becomes' do
      let(:attributes) do
        :title
      end

      let(:model) do
        test_model do
          field :settings, type: Hash
          attr_readonly :settings
        end
      end

      let(:subclass) do
        Class.new(model)
      end

      let(:original) do
        model.create!(settings: { 'enabled' => false })
      end

      it 'does not persist an in-place change to the readonly field of the became document' do
        became = original.becomes(subclass)
        became.settings['enabled'] = true
        became.save!

        expect(model.collection.find(_id: original.id).first['settings']).to eq('enabled' => false)
      end
    end

    context 'when a persisted document with embedded documents is converted with becomes' do
      let(:attributes) do
        :title
      end

      let(:person) do
        Person.create!(addresses: [ { street: 'Main', map: { 'enabled' => false } } ])
      end

      around do |example|
        original = Address.readonly_attributes
        Address.attr_readonly :map
        example.run
      ensure
        Address.readonly_attributes = original
      end

      it 'does not persist an in-place change to the readonly field of a became embedded document' do
        became = person.becomes(Person)
        became.addresses.first.map['enabled'] = true
        became.save!

        stored = Person.collection.find(_id: person.id).first['addresses'].first['map']
        expect(stored).to eq('enabled' => false)
      end
    end

    context 'when a new document is converted with becomes' do
      let(:attributes) do
        :title
      end

      let(:model) do
        test_model do
          field :settings, type: Hash
          attr_readonly :settings
        end
      end

      it 'reports the readonly value as a saved change when the became document is created' do
        became = model.new(settings: { 'enabled' => false }).becomes(model)
        became.save!

        expect(became.previous_changes['settings']).to eq([ nil, { 'enabled' => false } ])
        expect(model.collection.find(_id: became.id).first['settings']).to eq('enabled' => false)
      end
    end

    context 'when a field is named like an internal dirty tracking method' do
      let(:attributes) do
        :title
      end

      let(:model) do
        test_model do
          field :name, type: String
          field :readonly_change_ignored, type: String
        end
      end

      it 'tracks changes and creates the document' do
        document = model.new(name: 'original', readonly_change_ignored: 'value')

        expect(document.name_changed?).to be true

        document.save!

        expect(document.reload.name).to eq('original')
        expect(document.readonly_change_ignored).to eq('value')
        expect(document.readonly_change_ignored?).to be true
        expect(document).not_to be_changed
      end
    end

    context 'when a foreign_key is defined as readonly' do
      let(:attributes) do
        :mother_id
      end

      context 'when the relation exists' do
        let(:mother) do
          Person.create!
        end

        let(:child) do
          Person.create!(mother: mother)
          Person.find_by(mother: mother)
        end

        it 'the relation can still be accessed' do
          expect(child.mother).to eq(mother)
        end
      end

      context 'when the relation does not exist' do
        let(:child) do
          Person.create!
        end

        it 'the relation is nil' do
          expect(child.mother).to be_nil
        end
      end
    end

    context 'when a subclass inherits readonly fields' do
      let(:attributes) do
        %i[title terms]
      end

      before do
        class OldPerson < Person
          attr_readonly :age
        end
      end

      it 'ensures subclass inherits the readonly attributes from parent' do
        expect(OldPerson.readonly_attributes.to_a).to include('title', 'terms')
      end

      it "ensures subclass does not modify parent's readonly attributes" do
        expect(Person.readonly_attributes.to_a).not_to include('age')
      end
    end
  end
end
