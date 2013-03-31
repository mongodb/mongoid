require "spec_helper"

describe Mongoid::Criterion::Modifiable do

  describe ".find_or_create_by" do

    context "when the document is found" do

      context "when providing an attribute" do

        let!(:person) do
          Person.create(title: "Senior")
        end

        it "returns the document" do
          expect(Person.find_or_create_by(title: "Senior")).to eq(person)
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
              expect(from_db).to eq(game)
            end
          end

          context "when providing the proxy relation" do

            let(:from_db) do
              Game.find_or_create_by(person: game.person)
            end

            it "returns the document" do
              expect(from_db).to eq(game)
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
            expect(from_db).to eq(cookie)
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
          expect(from_db.person).to eq(person)
        end

        it "does not return an existing false document" do
          expect(from_db).to_not eq(game)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita")
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be_true
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
        expect(Person.find_or_initialize_by(title: "Senior")).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita")
        end

        it "creates a new document" do
          expect(person).to be_new_record
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          expect(person).to be_new_record
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be_true
        end
      end
    end
  end
end
