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
        Person.create
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
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "t")
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
          Person.create
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
  end

  context "when dynamic attributes are not enabled" do
    let(:account) do
      Account.create
    end

    it "raises exception for an unknown attribute " do
      expect {
        account.set(somethingnew: "somethingnew")
      }.to raise_error(Mongoid::Errors::UnknownAttribute)
    end
  end

  context "when dynamic attributes enabled" do
    let(:person) do
      Person.create
    end

    it "updates non existing attribute" do
      person.set(somethingnew: "somethingnew")
      expect(person.reload.somethingnew).to eq "somethingnew"
    end
  end

  context "with an attribute with private setter" do
    let(:agent) do
      Agent.create
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
        a.save
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
  end

  context 'when the field is a nested hash' do

    context 'when a leaf value in the nested hash is updated' do

      let(:church) do
        Church.new.tap do |a|
          a.location = {'address' => {'city' => 'Berlin', 'street' => 'Yorckstr'}}
          a.name = 'Church1'
          a.save
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


    context 'when the nested hash is many levels deep' do

      let(:church) do
        Church.new.tap do |a|
          a.location = {'address' => {'state' => {'address' => {'city' => 'Berlin', 'street' => 'Yorckstr'}}}}
          a.name = 'Church1'
          a.save
        end
      end

      before do
        church.set('location.address.state.address.city' => 'Munich')
      end

      it 'does not reset the nested hash' do
        expect(church.name).to eq('Church1')
        expect(church.location).to eql({'address' => {'state' => {'address' => {'city' => 'Munich', 'street' => 'Yorckstr'}}}})
      end
    end
  end

  context 'when the field is not already set locally' do

    let(:church) do
      Church.create
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
end
