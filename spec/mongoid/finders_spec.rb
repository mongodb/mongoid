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

  describe ".find_and_modify" do

    let!(:person) do
      Person.create(title: "Senior")
    end

    it "returns the document" do
      Person.find_and_modify(title: "Junior").should eq(person)
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

        context "with an owner with a BSON identity type" do
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
end
