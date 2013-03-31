require "spec_helper"

describe Mongoid::Persistable::Creatable do

  describe ".create" do

    context "when provided an array of attributes" do

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }])
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "passes the block to the first document" do
          expect(people.first.age).to eq(36)
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end

        it "passes the block to the second document" do
          expect(people.last.age).to eq(36)
        end
      end
    end

    context "when providing attributes" do

      let(:person) do
        Person.create(title: "Sensei")
      end

      it "it saves the document" do
        expect(person).to be_persisted
      end

      it "returns the document" do
        expect(person).to be_a_kind_of(Person)
      end

      context "when creating an embedded document" do

        let(:address) do
          Address.create(addressable: person)
        end

        it "persists the document" do
          expect(address).to be_persisted
        end
      end

      context "when creating an embedded document with store_as option" do

        let(:user) do
          User.create
        end

        before(:all) do
          User.embeds_many(
            :addresses,
            class_name: "Address",
            store_as: "user_adresses",
            validate: false
          )
          Address.embedded_in :user
        end

        before do
          user.addresses.create!(city: "nantes")
        end

        let(:document) do
          user.collection.find(_id: user.id).first
        end

        it "should not persist in address key on User document" do
          expect(document.keys).to_not include("addresses")
        end

        it "should persist on user_addesses key on User document" do
          expect(document.keys).to include("user_adresses")
        end
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        expect(person.ssn).to eq("666-66-6666")
      end

      it "persists the document" do
        expect(person).to be_persisted
      end
    end
  end

  describe ".create!" do

    context "when provided an array of attributes" do

      context "when no block is passed" do

        let(:people) do
          Person.create!([{ title: "sir" }, { title: "madam" }])
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create!([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "passes the block to the first document" do
          expect(people.first.age).to eq(36)
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end

        it "passes the block to the second document" do
          expect(people.last.age).to eq(36)
        end
      end
    end

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        before do
          Person.create_indexes
        end

        it "raises an error" do
          expect {
            4.times { Person.with(safe: true).create!(ssn: "555-55-1029") }
          }.to raise_error
        end
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create! do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        expect(person.ssn).to eq("666-66-6666")
      end

      it "persists the document" do
        expect(person).to be_persisted
      end
    end

    context "when setting the composite key" do

      let(:account) do
        Account.create!(name: "Hello")
      end

      it "saves the document" do
        expect(account).to be_persisted
      end
    end

    context "when a callback returns false" do

      it "raises a callback error" do
        expect { Oscar.create! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end
end
