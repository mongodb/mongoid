require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::ManyToMany do

  let(:person) do
    Person.new
  end

  describe "#build" do

    let(:person) do
      Person.new
    end

    context "when no documents found in the database" do

      context "when the ids are empty" do

        it "returns an empty array" do
          person.preferences.should be_empty
        end
      end

      context "when the ids are incorrect" do

        before do
          person.preference_ids = [ BSON::ObjectId.new ]
        end

        it "returns an empty array" do
          person.preferences.should be_empty
        end
      end
    end
  end

  context "when the foreign key is nil" do

    let(:builder) do
      described_class.new(person, Person.relations["preferences"], nil)
    end

    let(:criteria) do
      builder.build
    end

    it "returns the criteria" do
      criteria.should eq([])
    end
  end
end
