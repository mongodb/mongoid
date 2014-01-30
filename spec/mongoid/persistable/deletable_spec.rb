require "spec_helper"

describe Mongoid::Persistable::Deletable do

  describe "#delete" do

    let!(:person) do
      Person.create
    end

    context "when deleting a readonly document" do

      let(:from_db) do
        Person.only(:_id).first
      end

      it "raises an error" do
        expect {
          from_db.delete
        }.to raise_error(Mongoid::Errors::ReadonlyDocument)
      end
    end

    context "when removing a root document" do

      let!(:deleted) do
        person.delete
      end

      it "deletes the document from the collection" do
        expect {
          Person.find(person.id)
        }.to raise_error
      end

      it "returns true" do
        expect(deleted).to be true
      end

      it "resets the flagged for destroy flag" do
        expect(person).to_not be_flagged_for_destroy
      end
    end

    context "when removing an embedded document" do

      let(:address) do
        person.addresses.build(street: "Bond Street")
      end

      context "when the document is not yet saved" do

        before do
          address.delete
        end

        it "removes the document from the parent" do
          expect(person.addresses).to be_empty
        end

        it "removes the attributes from the parent" do
          expect(person.raw_attributes["addresses"]).to be_nil
        end

        it "resets the flagged for destroy flag" do
          expect(address).to_not be_flagged_for_destroy
        end
      end

      context "when the document has been saved" do

        before do
          address.save
          address.delete
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "removes the object from the parent and database" do
          expect(from_db.addresses).to be_empty
        end
      end
    end

    context "when removing deeply embedded documents" do

      context "when the document has been saved" do

        let(:address) do
          person.addresses.create(street: "Bond Street")
        end

        let(:location) do
          address.locations.create(name: "Home")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          location.delete
        end

        it "removes the object from the parent and database" do
          expect(from_db.addresses.first.locations).to be_empty
        end

        it "resets the flagged for destroy flag" do
          expect(location).to_not be_flagged_for_destroy
        end
      end
    end

    context "when deleting subclasses" do

      let!(:firefox) do
        Firefox.create(name: "firefox")
      end

      let!(:firefox2) do
        Firefox.create(name: "firefox 2")
      end

      let!(:browser) do
        Browser.create(name: "browser")
      end

      let!(:canvas) do
        Canvas.create(name: "canvas")
      end

      context "when deleting a single document" do

        before do
          firefox.delete
        end

        it "deletes from the parent class collection" do
          expect(Canvas.count).to eq(3)
        end

        it "returns correct counts for child classes" do
          expect(Firefox.count).to eq(1)
        end

        it "returns correct counts for root subclasses" do
          expect(Browser.count).to eq(2)
        end
      end

      context "when deleting all documents" do

        before do
          Firefox.delete_all
        end

        it "deletes from the parent class collection" do
          expect(Canvas.count).to eq(2)
        end

        it "returns correct counts for child classes" do
          expect(Firefox.count).to eq(0)
        end

        it "returns correct counts for root subclasses" do
          expect(Browser.count).to eq(1)
        end
      end
    end
  end

  describe "#delete_all" do

    let!(:person) do
      Person.create(title: "sir")
    end

    context "when no conditions are provided" do

      let!(:removed) do
        Person.delete_all
      end

      it "removes all the documents" do
        expect(Person.count).to eq(0)
      end

      it "returns the number of documents removed" do
        expect(removed).to eq(1)
      end
    end

    context "when conditions are provided" do

      let!(:person_two) do
        Person.create
      end

      context "when no conditions attribute provided" do

        let!(:removed) do
          Person.delete_all(title: "sir")
        end

        it "removes the matching documents" do
          expect(Person.count).to eq(1)
        end

        it "returns the number of documents removed" do
          expect(removed).to eq(1)
        end
      end
    end
  end
end
