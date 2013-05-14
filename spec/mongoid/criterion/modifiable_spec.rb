require "spec_helper"

describe Mongoid::Criterion::Modifiable do

  describe ".find_or_create_by" do

    context "when the document is found" do

      context "when providing an attribute" do

        let!(:person) do
          Person.create(title: "Senior")
        end

        it "returns the document" do
          Person.find_or_create_by(title: "Senior").should eq(person)
        end
      end

      context "when providing a document" do

        context "with an owner with a BSON identity type" do

          let!(:person) do
            Person.create
          end

          let!(:game) do
            Game.create(person: person)
          end

          context "when providing the object directly" do

            let(:from_db) do
              Game.find_or_create_by(person: person)
            end

            it "returns the document" do
              from_db.should eq(game)
            end
          end

          context "when providing the proxy relation" do

            let(:from_db) do
              Game.find_or_create_by(person: game.person)
            end

            it "returns the document" do
              from_db.should eq(game)
            end
          end
        end

        context "with an owner with an Integer identity type" do

          let!(:jar) do
            Jar.create
          end

          let!(:cookie) do
            Cookie.create(jar: jar)
          end

          let(:from_db) do
            Cookie.find_or_create_by(jar: jar)
          end

          it "returns the document" do
            from_db.should eq(cookie)
          end
        end
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
        end

        let!(:game) do
          Game.create
        end

        let(:from_db) do
          Game.find_or_create_by(person: person)
        end

        it "returns the new document" do
          from_db.person.should eq(person)
        end

        it "does not return an existing false document" do
          from_db.should_not eq(game)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita")
        end

        it "creates a persisted document" do
          person.should be_persisted
        end

        it "sets the attributes" do
          person.title.should eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          person.should be_persisted
        end

        it "sets the attributes" do
          person.title.should eq("Senorita")
        end

        it "calls the block" do
          person.pets.should be_true
        end
      end
    end
  end

  describe ".find_or_initialize_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(title: "Senior")
      end

      it "returns the document" do
        Person.find_or_initialize_by(title: "Senior").should eq(person)
      end
    end

    context "when the document is not found" do

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita")
        end

        it "creates a new document" do
          person.should be_new_record
        end

        it "sets the attributes" do
          person.title.should eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          person.should be_new_record
        end

        it "sets the attributes" do
          person.title.should eq("Senorita")
        end

        it "calls the block" do
          person.pets.should be_true
        end
      end
    end
  end

  describe "first_or_create" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    context "when the document is found" do

      let(:found) do
        Band.where(name: "Depeche Mode").first_or_create
      end

      it "returns the document" do
        expect(found).to eq(band)
      end
    end

    context "when the document is not found" do

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create(origin: "Essex")
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "sets the additional attributes" do
          expect(document.origin).to eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "yields to the block" do
          expect(document.active).to be_false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_create(active: false)
          end

          it "returns a new document" do
            expect(document.active).to be_false
          end

          it "returns a persisted document" do
            expect(document).to be_persisted
          end
        end
      end
    end
  end

  describe "first_or_create!" do

    context "when validation fails on the new document" do

      it "raises an error" do
        expect {
          Account.where(number: "12345").first_or_create!
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when passing a block" do

      let(:account) do
        Account.where(number: "12345").first_or_create! do |account|
          account.name = "testing"
        end
      end

      it "passes the block to the create call" do
        expect(account.name).to eq("testing")
      end

      it "persists the new document" do
        expect(account).to be_persisted
      end
    end

    context "when the document is found" do

      let!(:band) do
        Band.with(safe: true).create!(name: "Depeche Mode")
      end

      let(:found) do
        Band.where(name: "Depeche Mode").first_or_create!
      end

      it "returns the document" do
        expect(found).to eq(band)
      end
    end

    context "when the document is not found" do

      let!(:band) do
        Band.with(safe: true).create!(name: "Depeche Mode")
      end

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create!(origin: "Essex")
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "sets the additional attributes" do
          expect(document.origin).to eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create!
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create! do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "yields to the block" do
          expect(document.active).to be_false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_create!(active: false)
          end

          it "returns a new document" do
            expect(document.active).to be_false
          end

          it "returns a persisted document" do
            expect(document).to be_persisted
          end
        end
      end
    end
  end
end
