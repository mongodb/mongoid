require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::Many do

  let(:base) do
    stub
  end

  describe "#build" do

    let(:criteria) do
      stub(klass: Post, selector: { "person_id" => "" }, selector_with_type_selection: { "person_id" => "" })
    end

    let(:metadata) do
      stub(
        klass: Post,
        name: :posts,
        foreign_key: "person_id",
        inverse_klass: Person,
        criteria: criteria,
      )
    end

    let(:builder) do
      described_class.new(base, metadata, object)
    end

    context "when provided an id" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:object) do
        object_id
      end

      let(:post) do
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
          name: :posts,
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
        object_id
      end

      let(:post) do
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

      let(:metadata) do
        stub(
          klass: Post,
          name: :posts,
          foreign_key: "person_id",
          inverse_klass: Person
        )
      end

      let(:object) do
        [ Person.new ]
      end

      let(:documents) do
        builder.build
      end

      it "returns the object" do
        documents.should eq(object)
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
          person.posts.should be_empty
        end

        context "during initialization" do

          it "returns an empty array" do
            Person.new do |p|
              p.posts.should be_empty
              p.posts.metadata.should_not be_nil
            end
          end
        end
      end
    end
  end
end
