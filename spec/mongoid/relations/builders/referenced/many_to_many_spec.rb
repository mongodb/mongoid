require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::ManyToMany do

  let(:person) do
    Person.new
  end

  let(:base) do
    stub
  end

  describe "#build" do

    let(:criteria) do
      stub(klass: Preference, selector: { "_id" => { "$in" => [] }})
    end

    let(:metadata) do
      stub(
        klass: Preference,
        name: :preferences,
        foreign_key: "preference_ids",
        criteria: criteria
      )
    end

    let(:builder) do
      described_class.new(base, metadata, object)
    end

    context "when provided ids" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:preference) do
        stub
      end

      let(:documents) do
        builder.build
      end

      it "sets the documents" do
        documents.should eq(criteria)
      end
    end

    context "when order specified" do

      let(:metadata) do
        stub(
          klass: Post,
          name: :preferences,
          foreign_key: "person_id",
          inverse_klass: Person,
          order: :rating.asc,
          criteria: criteria
        )
      end

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:preference) do
        stub
      end

      let(:documents) do
        builder.build
      end

      it "ordered by specified filed" do
        documents.should eq(criteria)
      end
    end

    context "when provided a object" do

      context "when the object is not nil" do

        let(:object) do
          [ Post.new ]
        end

        let(:preference) do
          stub
        end

        let!(:documents) do
          builder.build
        end

        it "returns the objects" do
          documents.should eq(object)
        end
      end

      context "when the object is nil" do

        let(:metadata) do
          stub(
            klass: Post,
            name: :preferences,
            foreign_key: "preference_ids",
            criteria: criteria
          )
        end

        let(:object) do
          nil
        end

        let!(:documents) do
          builder.build
        end

        it "returns the object" do
          documents.should eq(criteria)
        end
      end
    end
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
          person.preference_ids = [ Moped::BSON::ObjectId.new ]
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
      criteria.should be_empty
    end
  end
end
