require "spec_helper"

describe Mongoid::Finders do

  describe ".all_in" do

    let(:criteria) do
      Person.all_in(aliases: [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should eq({ aliases: { "$all" => [ "Bond", "007" ] } })
    end
  end

  describe ".any_in" do

    let(:criteria) do
      Person.any_in(aliases: [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should eq({ aliases: { "$in" => [ "Bond", "007" ] } })
    end
  end

  describe ".excludes" do

    let(:criteria) do
      Person.excludes(title: "Sir")
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should eq({ title: { "$ne" => "Sir" } })
    end
  end

  describe "#find" do

    context "when using integer ids" do

      before(:all) do
        Person.field(:_id, type: Integer)
      end

      after(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      context "when passed a string" do

        let!(:person) do
          Person.create do |doc|
            doc._id = 1
          end
        end

        let(:from_db) do
          Person.find("1")
        end

        it "returns the matching document" do
          from_db.should eq(person)
        end
      end

      context "when passed an array of strings" do

        let!(:person) do
          Person.create do |doc|
            doc._id = 2
          end
        end

        let(:from_db) do
          Person.find([ "2" ])
        end

        it "returns the matching documents" do
          from_db.should eq([ person ])
        end
      end
    end

    context "when using string ids" do

      let!(:person) do
        Person.create(title: "Mrs.")
      end

      let!(:documents) do
        3.times.map do |n|
          Person.create(title: "Mr.")
        end
      end

      before(:all) do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new.to_s }
        )
      end

      after(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      context "with an id as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id).should eq(person)
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new.to_s)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when the identity map is enabled" do

          before do
            Mongoid.identity_map_enabled = true
          end

          after do
            Mongoid.identity_map_enabled = false
          end

          context "when the document is found in the map" do

            before do
              Mongoid::IdentityMap.set(person)
            end

            let(:from_map) do
              Person.find(person.id)
            end

            it "returns the document" do
              from_map.should eq(person)
            end

            it "returns the same instance" do
              from_map.should equal(person)
            end
          end

          context "when the document is not found in the map" do

            let(:from_db) do
              Person.find(person.id)
            end

            it "returns the document from the database" do
              from_db.should eq(person)
            end

            it "returns a different instance" do
              from_db.should_not equal(person)
            end
          end
        end
      end

      context "when passed an array of ids" do

        context "when the documents are found" do

          let(:people) do
            Person.find(documents.map(&:id))
          end

          it "returns an array of the documents" do
            people.should eq(documents)
          end
        end

        context "when no documents found" do

          it "raises an error" do
            expect {
              Person.find([
                BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s
              ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passing an empty array" do

        let(:people) do
          Person.find([])
        end

        it "returns an empty array" do
          people.should be_empty
        end
      end
    end

    context "when using object ids" do

      let!(:person) do
        Person.create(title: "Mrs.")
      end

      let!(:documents) do
        3.times.map do |n|
          Person.create(title: "Mr.")
        end
      end

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      context "when passed a BSON::ObjectId as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id).should eq(person)
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passed a string id as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id.to_s).should eq(person)
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new.to_s)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passed an array of ids as args" do

        context "when the documents are found" do

          let(:people) do
            Person.find(documents.map(&:id))
          end

          it "returns an array of the documents" do
            people.should eq(documents)
          end
        end

        context "when no documents found" do

          it "raises an error" do
            expect {
              Person.find([
                BSON::ObjectId.new, BSON::ObjectId.new
              ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end
    end
  end

  describe ".find_or_create_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(title: "Senior")
      end

      it "returns the document" do
        Person.find_or_create_by(title: "Senior").should eq(person)
      end
    end

    context "when the document is not found" do

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

  describe ".only" do

    let(:criteria) do
      Person.only(:title, :age)
    end

    it "returns a new criteria with select conditions added" do
      criteria.options.should eq({ fields: {_type: 1, title: 1, age: 1} })
    end
  end

  describe ".where" do

    let(:criteria) do
      Person.where(title: "Sir")
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should eq({ title: "Sir" })
    end
  end

  describe ".near" do

    let(:criteria) do
      Address.near(latlng: [37.761523, -122.423575, 1])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should eq(
        { latlng: { "$near" => [37.761523, -122.423575, 1] }}
      )
    end
  end
end
