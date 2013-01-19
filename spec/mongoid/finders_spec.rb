require "spec_helper"

describe Mongoid::Finders do

  describe ".distinct" do

    before do
      Band.create(name: "Tool")
      Band.create(name: "Photek")
    end

    it "returns the distinct values for the field" do
      Band.distinct(:name).should eq([ "Tool", "Photek" ])
    end
  end

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

  describe ".each_with_index" do

    let!(:band) do
      Band.create
    end

    it "iterates through all documents" do
      Band.each_with_index do |band, index|
        index.should eq(0)
      end
    end
  end

  describe ".find_and_modify" do

    let!(:person) do
      Person.create(title: "Senior")
    end

    it "returns the document" do
      Person.find_and_modify(title: "Junior").should eq(person)
    end
  end

  describe ".find_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(title: "sir")
      end

      context "when no block is provided" do

        it "returns the document" do
          Person.find_by(title: "sir").should eq(person)
        end
      end

      context "when a block is provided" do

        let(:result) do
          Person.find_by(title: "sir") do |peep|
            peep.age = 50
          end
        end

        it "yields the returned document" do
          result.age.should eq(50)
        end
      end
    end

    context "when the document is not found" do

      context "when raising a not found error" do

        before do
          Mongoid.raise_not_found_error = true
        end

        it "raises an error" do
          expect {
            Person.find_by(ssn: "333-22-1111")
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when raising no error" do

        before do
          Mongoid.raise_not_found_error = false
        end

        after do
          Mongoid.raise_not_found_error = true
        end

        context "when no block is provided" do

          it "returns nil" do
            Person.find_by(ssn: "333-22-1111").should be_nil
          end
        end

        context "when a block is provided" do

          let(:result) do
            Person.find_by(ssn: "333-22-1111") do |peep|
              peep.age = 50
            end
          end

          it "returns nil" do
            result.should be_nil
          end
        end
      end
    end
  end

  describe ".first_or_create" do

    context "when the document is found" do

      let!(:person) do
        Person.create
      end

      it "returns the document" do
        Person.first_or_create.should eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
        end

        let(:from_db) do
          Game.first_or_create(person: person)
        end

        it "returns the new document" do
          from_db.person.should eq(person)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.first_or_create(title: "Senorita")
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
          Person.first_or_create(title: "Senorita") do |person|
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

  describe ".first_or_initialize" do

    context "when the document is found" do

      let!(:person) do
        Person.create
      end

      it "returns the document" do
        Person.first_or_create.should eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
        end

        let(:found) do
          Game.first_or_initialize(person: person)
        end

        it "returns the new document" do
          found.person.should eq(person)
        end

        it "does not save the document" do
          found.should_not be_persisted
        end
      end

      context "when not providing a block" do

        before do
          Person.delete_all
        end

        let!(:person) do
          Person.first_or_initialize(title: "esquire")
        end

        it "creates a non persisted document" do
          person.should_not be_persisted
        end

        it "sets the attributes" do
          person.title.should eq("esquire")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.first_or_initialize(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          person.should_not be_persisted
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

  describe ".pluck" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 3)
    end

    let!(:photek) do
      Band.create(name: "Photek", likes: 1)
    end

    context "when field values exist" do

      let(:plucked) do
        Band.pluck(:name)
      end

      it "returns the field values" do
        plucked.should eq([ "Depeche Mode", "Tool", "Photek" ])
      end
    end

    context "when field values do not exist" do

      let(:plucked) do
        Band.pluck(:follows)
      end

      it "returns an empty array" do
        plucked.should be_empty
      end
    end
  end

  Origin::Selectable.forwardables.each do |method|

    describe "##{method}" do

      it "forwards the #{method} to the criteria" do
        Band.should respond_to(method)
      end
    end
  end
end
