require "spec_helper"

describe Mongoid::Reloading do

  describe "#reload" do

    context "when using bson ids" do

      let(:person) do
        Person.create
      end

      let!(:from_db) do
        Person.find(person.id).tap do |peep|
          peep.age = 35
          peep.save
        end
      end

      it "reloads the object attributes from the db" do
        person.reload
        person.age.should eq(35)
      end

      it "reload should return self" do
        person.reload.should eq(from_db)
      end
    end

    context "when using string ids" do

      let(:account) do
        Account.create(name: "bank", number: "1000")
      end

      let!(:from_db) do
        Account.find(account.id).tap do |acc|
          acc.number = "1001"
          acc.save
        end
      end

      it "reloads the object attributes from the db" do
        account.reload
        account.number.should eq("1001")
      end

      it "reload should return self" do
        account.reload.should eq(from_db)
      end
    end

    context "when an after initialize callback is defined" do

      let!(:book) do
        Book.create(title: "Snow Crash")
      end

      before do
        book.update_attribute(:chapters, 50)
        book.reload
      end

      it "runs the callback" do
        book.chapters.should eq(5)
      end
    end

    context "when the document was dirty" do

      let(:person) do
        Person.create
      end

      before do
        person.title = "Sir"
        person.reload
      end

      it "resets the dirty modifications" do
        person.changes.should be_empty
      end
    end

    context "when document not saved" do

      context "when raising not found error" do

        it "raises an error" do
          expect {
            Person.new.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      context "when embedded a single level" do

        context "when the relation is an embeds many" do

          let!(:address) do
            person.addresses.create(street: "Abbey Road", number: 4)
          end

          before do
            Person.collection.find(
              { "_id" => person.id }
            ).update({ "$set" => { "addresses.0.number" => 3 }})
          end

          let!(:reloaded) do
            address.reload
          end

          it "reloads the embedded document attributes" do
            reloaded.number.should eq(3)
          end

          it "reloads the reference on the parent" do
            person.addresses.first.should eq(reloaded)
          end

          it "retains the relation to the parent" do
            reloaded.addressable.should eq(person)
          end
        end

        context "when the relation is an embeds one" do

          let!(:name) do
            person.create_name(first_name: "Syd")
          end

          before do
            Person.collection.find({ "_id" => person.id }).
              update({ "$set" => { "name.last_name" => "Vicious" }})
          end

          let!(:reloaded) do
            name.reload
          end

          it "reloads the embedded document attributes" do
            reloaded.last_name.should eq("Vicious")
          end

          it "reloads the reference on the parent" do
            person.name.should eq(reloaded)
          end

          it "retains the relation to the parent" do
            reloaded.namable.should eq(person)
          end
        end
      end

      context "when the relation is embedded multiple levels" do

        let!(:address) do
          person.addresses.create(street: "Abbey Road", number: 3)
        end

        let!(:location) do
          address.locations.create(name: "home")
        end

        before do
          Person.collection.find({ "_id" => person.id }).
            update({ "$set" => { "addresses.0.locations.0.name" => "work" }})
        end

        let!(:reloaded) do
          location.reload
        end

        it "reloads the embedded document attributes" do
          reloaded.name.should eq("work")
        end

        it "reloads the reference on the parent" do
          address.locations.first.should eq(reloaded)
        end

        it "reloads the reference on the root" do
          person.addresses.first.locations.first.should eq(reloaded)
        end
      end
    end

    context "when embedded documents change" do

      let(:person) do
        Person.create
      end

      let!(:address) do
        person.addresses.create(number: 27, street: "Maiden Lane")
      end

      before do
        Person.collection.find({ "_id" => person.id }).
          update({ "$set" => { "addresses" => [] }})
        person.reload
      end

      it "reloads the association" do
        person.addresses.should be_empty
      end
    end

    context "with relational associations" do

      let(:person) do
        Person.create
      end

      context "for a references_one" do

        let!(:game) do
          person.create_game(score: 50)
        end

        before do
          Game.collection.find({ "_id" => game.id }).
            update({ "$set" => { "score" => 75 }})
          person.reload
        end

        it "reloads the association" do
          person.game.score.should eq(75)
        end
      end

      context "for a referenced_in" do

        let!(:game) do
          person.create_game(score: 50)
        end

        before do
          Person.collection.find({ "_id" => person.id }).
            update({ "$set" => { "title" => "Mam" }})
          game.reload
        end

        it "reloads the association" do
          game.person.title.should eq("Mam")
        end
      end
    end
  end
end
