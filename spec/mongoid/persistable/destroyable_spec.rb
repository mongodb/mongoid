require "spec_helper"

describe Mongoid::Persistable::Destroyable do

  describe "#destroy" do

    let!(:person) do
      Person.create
    end

    context "when destroying a readonly document" do

      let(:from_db) do
        Person.only(:_id).first
      end

      it "raises an error" do
        expect {
          from_db.destroy
        }.to raise_error(Mongoid::Errors::ReadonlyDocument)
      end
    end

    context "when removing a root document" do

      let!(:destroyd) do
        person.destroy
      end

      it "destroys the document from the collection" do
        expect {
          Person.find(person.id)
        }.to raise_error
      end

      it "returns true" do
        expect(destroyd).to be true
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
          address.destroy
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
          address.destroy
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "removes the object from the parent and database" do
          expect(from_db.addresses).to be_empty
        end
      end

      context 'when removing from a list of embedded documents' do

        context 'when the embedded documents list is reversed in memory' do

          let(:word) do
            Word.create!(name: 'driver')
          end

          let(:from_db) do
            Word.find(word.id)
          end

          before do
            word.definitions.find_or_create_by(description: 'database connector')
            word.definitions.find_or_create_by(description: 'chauffeur')
            word.definitions = word.definitions.reverse
            word.definitions.last.destroy
          end

          it 'removes the embedded document in memory' do
            expect(word.definitions.size).to eq(1)
          end

          it 'removes the embedded document in the database' do
            expect(from_db.definitions.size).to eq(1)
          end
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
          location.destroy
        end

        it "removes the object from the parent and database" do
          expect(from_db.addresses.first.locations).to be_empty
        end

        it "resets the flagged for destroy flag" do
          expect(location).to_not be_flagged_for_destroy
        end
      end
    end
  end

  describe "#destroy!" do

    context "when no validation callback returns false" do

      let(:person) do
        Person.create
      end

      it "returns true" do
        expect(person.destroy!).to eq(true)
      end
    end

    context "when a validation callback returns false" do

      let(:album) do
        Album.create
      end

      before do
        expect(album).to receive(:set_parent_name).and_return(false)
      end

      it "raises an exception" do
        expect {
          album.destroy!
        }.to raise_error(Mongoid::Errors::DocumentNotDestroyed)
      end
    end
  end

  describe "#destroy_all" do

    let!(:person) do
      Person.create(title: "sir")
    end

    context "when no conditions are provided" do

      let!(:removed) do
        Person.destroy_all
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
          Person.destroy_all(title: "sir")
        end

        it "removes the matching documents" do
          expect(Person.count).to eq(1)
        end

        it "returns the number of documents removed" do
          expect(removed).to eq(1)
        end
      end
    end

    context 'when removing a list of embedded documents' do

      context 'when the embedded documents list is reversed in memory' do

        let(:word) do
          Word.create!(name: 'driver')
        end

        before do
          word.definitions.find_or_create_by(description: 'database connector')
          word.definitions.find_or_create_by(description: 'chauffeur')
          word.definitions = word.definitions.reverse
          word.definitions.destroy_all
        end

        it 'removes all embedded documents' do
          expect(word.definitions.size).to eq(0)
        end
      end
    end
  end
end
