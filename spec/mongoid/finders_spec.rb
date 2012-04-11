require "spec_helper"

describe Mongoid::Finders do

  describe ".each" do

    let!(:band) do
      Band.create
    end

    it "iterates through all documents" do
      Band.each do |band|
        band.should be_a(Band)
      end
    end
  end

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

        let!(:person) do
          Person.create
        end

        let!(:game) do
          Game.create(person: person)
        end

        let(:from_db) do
          Game.find_or_create_by(person: person)
        end

        it "returns the document" do
          from_db.should eq(game)
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

  describe ".find_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(title: "sir")
      end

      it "returns the document" do
        Person.find_by(title: "sir").should eq(person)
      end
    end

    context "when the document is not found" do

      it "raises an error" do
        expect {
          Person.find_by(ssn: "333-22-1111")
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end
end
