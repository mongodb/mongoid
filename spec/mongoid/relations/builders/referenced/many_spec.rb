require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::Many do

  let(:base) do
    double
  end

  describe "#build" do

    let(:criteria) do
      double(klass: Post, selector: { "person_id" => "" }, selector_with_type_selection: { "person_id" => "" })
    end

    let(:metadata) do
      double(
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
        BSON::ObjectId.new
      end

      let(:object) do
        object_id
      end

      let(:post) do
        double
      end

      let(:documents) do
        builder.build
      end

      it "sets the documents" do
        expect(documents).to eq(criteria)
      end
    end

    context "when order specified" do

      let(:metadata) do
        double(
          klass: Post,
          name: :posts,
          foreign_key: "person_id",
          inverse_klass: Person,
          order: :rating.asc,
          criteria: criteria
        )
      end

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:object) do
        object_id
      end

      let(:post) do
        double
      end

      let(:documents) do
        builder.build
      end

      it "ordered by specified filed" do
        expect(documents).to eq(criteria)
      end
    end

    context "when provided a object" do

      let(:metadata) do
        double(
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
        expect(documents).to eq(object)
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
          expect(person.posts).to be_empty
        end

        context "during initialization" do

          it "returns an empty array" do
            Person.new do |p|
              expect(p.posts).to be_empty
              expect(p.posts.__metadata).to_not be_nil
            end
          end
        end
      end
    end
  end
end
