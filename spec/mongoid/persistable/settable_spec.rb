# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Settable do

  describe "#set" do

    context "when the document is a root document" do

      shared_examples_for "a settable root document" do

        it "sets the normal field to the new value" do
          expect(person.title).to eq("kaiser")
        end

        it "properly sets aliased fields" do
          expect(person.test).to eq("alias-test")
        end

        it "casts fields that need typecasting" do
          expect(person.dob).to eq(date)
        end

        it "returns self object" do
          expect(set).to eq(person)
        end

        it "persists the normal field set" do
          expect(person.reload.title).to eq("kaiser")
        end

        it "persists sets on aliased fields" do
          expect(person.reload.test).to eq("alias-test")
        end

        it "persists fields that need typecasting" do
          expect(person.reload.dob).to eq(date)
        end

        it "resets the dirty attributes for the sets" do
          expect(person).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      context "when provided string fields" do

        let!(:set) do
          person.set("title" => "kaiser", "test" => "alias-test", "dob" => date)
        end

        it_behaves_like "a settable root document"
      end

      context "when provided symbol fields" do

        let!(:set) do
          person.set(title: "kaiser", test: "alias-test", dob: date)
        end

        it_behaves_like "a settable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a settable embedded document" do

        it "sets the normal field to the new value" do
          expect(address.number).to eq(44)
        end

        it "properly sets aliased fields" do
          expect(address.suite).to eq("400")
        end

        it "casts fields that need typecasting" do
          expect(address.end_date).to eq(date)
        end

        it "returns self object" do
          expect(set).to eq(address)
        end

        it "persists the normal field set" do
          expect(address.reload.number).to eq(44)
        end

        it "persists the aliased field set" do
          expect(address.reload.suite).to eq("400")
        end

        it "persists the fields that need typecasting" do
          expect(address.reload.end_date).to eq(date)
        end

        it "resets the dirty attributes for the sets" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t")
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      context "when provided string fields" do

        let!(:set) do
          address.set("number" => 44, "suite" => "400", "end_date" => date)
        end

        it_behaves_like "a settable embedded document"
      end

      context "when provided symbol fields" do

        let!(:set) do
          address.set(number: 44, suite: "400", end_date: date)
        end

        it_behaves_like "a settable embedded document"
      end

      context 'when the field is a relation' do

        let(:person) do
          Person.create!
        end

        let(:pet) do
          Animal.new(name: "somepet")
        end

        let(:home_phone) do
          Phone.new(number: "555-555-5555")
        end

        let(:office_phone) do
          Phone.new(number: "666-666-6666")
        end

        it "should persist changes of embeds_one field" do
          person.set(pet: pet)
          expect(person.reload.pet).to eq(pet)
        end

        it "should persist changes of embeds_many fields" do
          person.set({ phone_numbers: [home_phone, office_phone].map { |p| p.as_document} })
          expect(person.reload.phone_numbers).to eq([home_phone, office_phone])
        end
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(title: "sir", age: 30)
      end

      it "marks a dirty change for the set fields" do
        person.atomically do
          person.set title: "miss", age: 21
          expect(person.changes).to eq({"title" => ["sir", "miss"], "age" => [30, 21]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(title: "sir", age: 30)
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "title" => 1, "age" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.set(title: "miss", age: 21)
          expect(person.title).to eq("miss")
          expect(person.age).to eq(21)
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        before do
          person.readonly!
        end

        it "raises a ReadonlyDocument error" do
          expect(person).to be_readonly
          expect do
            person.set(title: "miss", age: 21)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end

  context "when dynamic attributes are not enabled" do
    let(:account) do
      Account.create!(name: 'Foobar')
    end

    it "raises exception for an unknown attribute " do
      expect {
        account.set(somethingnew: "somethingnew")
      }.to raise_error(Mongoid::Errors::UnknownAttribute)
    end
  end

  context "when dynamic attributes enabled" do
    let(:person) do
      Person.create!
    end

    it "updates non existing attribute" do
      person.set(somethingnew: "somethingnew")
      expect(person.reload.somethingnew).to eq "somethingnew"
    end
  end

  context "with an attribute with private setter" do
    let(:agent) do
      Agent.create!
    end

    let(:title) do
      "Double-Oh Seven"
    end

    it "updates the attribute" do
      agent.singleton_class.send :private, :title=
      agent.set(title: title)
      expect(agent.reload.title).to eq title
    end
  end

  context 'when the field is already set locally' do

    let(:church) do
      Church.new.tap do |a|
        a.location = { 'city' => 'Berlin' }
        a.name = 'Church1'
        a.save!
      end
    end

    context 'when the field is a Hash type' do

      before do
        church.set('location.neighborhood' => 'Kreuzberg')
      end

      it 'updates the hash while keeping existing key and values locally' do
        expect(church.location).to eq({ 'city' => 'Berlin', 'neighborhood' => 'Kreuzberg'})
      end

      it 'updates the hash in the database' do
        expect(church.reload.location).to eq({ 'city' => 'Berlin', 'neighborhood' => 'Kreuzberg'})
      end
    end

    context 'when the field is assigned with nil' do

      before do
        church.location = nil
        church.set('location.neighborhood' => 'Kreuzberg')
      end

      it 'updates the hash while keeping existing key and values locally' do
        expect(church.location).to eq({'neighborhood' => 'Kreuzberg'})
      end

      it 'updates the hash in the database' do
        expect(church.reload.location).to eq({'neighborhood' => 'Kreuzberg'})
      end
    end

    context 'when the field type is String' do

      before do
        church.set('name' => 'Church2')
      end

      it 'updates the field locally' do
        expect(church.name).to eq('Church2')
      end

      it 'updates the field in the database' do
        expect(church.reload.name).to eq('Church2')
      end
    end

    context 'when there are two fields of type Hash and String' do

      before do
        church.set('name' => 'Church2', 'location.street' => 'Yorckstr.')
      end

      it 'updates the fields locally' do
        expect(church.name).to eq('Church2')
        expect(church.location).to eq({ 'city' => 'Berlin', 'street' => 'Yorckstr.'})
      end

      it 'updates the fields in the database' do
        expect(church.reload.name).to eq('Church2')
        expect(church.reload.location).to eq({ 'city' => 'Berlin', 'street' => 'Yorckstr.'})
      end
    end

    context 'when the field is a nested hash' do

      context 'when the field is set to an empty hash' do

        before do
          church.set('location' => {})
        end

        it 'updates the field locally' do
          expect(church.location).to eq({})
        end

        it 'updates the field in the database' do
          expect(church.reload.location).to eq({})
        end
      end

      context 'when a leaf value in the nested hash is updated' do

        let(:church) do
          Church.new.tap do |a|
            a.location = {'address' => {'city' => 'Berlin', 'street' => 'Yorckstr'}}
            a.name = 'Church1'
            a.save!
          end
        end

        before do
          church.set('location.address.city' => 'Munich')
        end

        it 'does not reset the nested hash' do
          expect(church.name).to eq('Church1')
          expect(church.location).to eql({'address' => {'city' => 'Munich', 'street' => 'Yorckstr'}})
        end
      end

      context 'when a leaf value in the nested hash is updated to a number' do

        let(:church) do
          Church.new.tap do |a|
            a.location = {'address' => {'city' => 'Berlin', 'street' => 'Yorckstr'}}
            a.name = 'Church1'
            a.save!
          end
        end

        before do
          church.set('location.address.city' => 12345)
        end

        it 'updates the nested value to the correct value' do
          expect(church.name).to eq('Church1')
          expect(church.location).to eql({'address' => {'city' => 12345, 'street' => 'Yorckstr'}})
        end
      end

      context 'when the nested hash is many levels deep' do

        let(:church) do
          Church.new.tap do |a|
            a.location = {'address' => {'state' => {'address' => {'city' => 'Berlin', 'street' => 'Yorckstr'}}}}
            a.name = 'Church1'
            a.save!
          end
        end

        context 'setting value to a string' do
          it 'keeps peer attributes of the nested hash' do
            church.set('location.address.state.address.city' => 'Munich')

            expect(church.name).to eq('Church1')
            expect(church.location).to eql({'address' => {'state' => {'address' => {'city' => 'Munich', 'street' => 'Yorckstr'}}}})
          end

          it 'removes lower level attributes of the nested hash' do
            church.set('location.address.state.address' => 'hello')

            expect(church.name).to eq('Church1')
            expect(church.location).to eql({'address' => {'state' => {'address' => 'hello'}}})
          end
        end

        context 'setting value to a hash' do
          it 'keeps peer attributes of the nested hash' do
            church.set('location.address.state.address.city' => {'hello' => 'world'})

            expect(church.name).to eq('Church1')
            expect(church.location).to eql({'address' => {'state' => {'address' => {'city' => {'hello' => 'world'}, 'street' => 'Yorckstr'}}}})
          end

          it 'removes lower level attributes of the nested hash' do
            church.set('location.address.state.address' => {'hello' => 'world'})

            expect(church.name).to eq('Church1')
            expect(church.location).to eql({'address' => {'state' => {'address' => {'hello' => 'world'}}}})
          end
        end
      end
    end

    context 'when nested field is an array' do
      let(:church) do
        Church.create!(
          location: {'address' => ['one', 'two']}
        )
      end

      context 'setting to a different array' do
        it 'sets values to new array discarding old values' do
          church.set('location.address' => ['three'])

          expect(church.location).to eq('address' => ['three'])
          church.reload
          expect(church.location).to eq('address' => ['three'])
        end
      end

      context 'changing from an array to a number' do
        it 'sets value to the number' do
          church.set('location.address' => 5)

          expect(church.location).to eq('address' => 5)
          church.reload
          expect(church.location).to eq('address' => 5)
        end
      end
    end

    context 'when nested field is not an array' do
      let(:church) do
        Church.create!(
          location: {'address' => 5}
        )
      end

      context 'setting to an array' do
        it 'sets values to the array' do
          church.set('location.address' => ['three'])

          expect(church.location).to eq('address' => ['three'])
          church.reload
          expect(church.location).to eq('address' => ['three'])
        end
      end
    end

    context 'when nesting into a field that is not a hash' do
      let(:church) do
        Church.create!(
          location: {'address' => 5}
        )
      end

      it 'sets field to new hash value discarding original value' do
        church.set('location.address.a' => 'test')

        expect(church.location).to eq('address' => {'a' => 'test'})
        church.reload
        expect(church.location).to eq('address' => {'a' => 'test'})
      end
    end
  end

  context 'when the field is not already set locally' do

    let(:church) do
      Church.create!
    end

    context 'when the field is a Hash type' do

      before do
        church.set('location.neighborhood' => 'Kreuzberg')
      end

      it 'sets the hash locally' do
        expect(church.location).to eq({ 'neighborhood' => 'Kreuzberg'})
      end

      it 'sets the hash in the database' do
        expect(church.reload.location).to eq({ 'neighborhood' => 'Kreuzberg'})
      end
    end

    context 'when the field type is String' do

      before do
        church.set('name' => 'Church2')
      end

      it 'sets the field locally' do
        expect(church.name).to eq('Church2')
      end

      it 'sets the field in the database' do
        expect(church.reload.name).to eq('Church2')
      end
    end

    context 'when there are two fields of type Hash and String' do

      before do
        church.set('name' => 'Church2', 'location.street' => 'Yorckstr.')
      end

      it 'sets the fields locally' do
        expect(church.name).to eq('Church2')
        expect(church.location).to eq({ 'street' => 'Yorckstr.'})
      end

      it 'sets the fields in the database' do
        expect(church.reload.name).to eq('Church2')
        expect(church.reload.location).to eq({ 'street' => 'Yorckstr.'})
      end
    end
  end

  context "when the field being set was projected out" do
    let(:full_agent) do
      Agent.create!(title: "Double-Oh Eight")
    end

    let(:agent) do
      Agent.where(_id: full_agent.id).only(:dob).first
    end

    context 'field exists in database' do
      it "raises MissingAttributeError" do
        lambda do
          agent.set(title: '008')
        end.should raise_error(ActiveModel::MissingAttributeError)

        expect(agent.reload.title).to eq 'Double-Oh Eight'
      end
    end

    context 'field does not exist in database' do
      it "raises MissingAttributeError" do
        lambda do
          agent.set(number: '008')
        end.should raise_error(ActiveModel::MissingAttributeError)

        expect(agent.reload.read_attribute(:number)).to be nil
      end
    end
  end
end
