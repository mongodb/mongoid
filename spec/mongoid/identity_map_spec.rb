require "spec_helper"

describe Mongoid::IdentityMap do

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  let(:identity_map) do
    described_class.new
  end

  describe "#clear" do

    before do
      identity_map.set(Person.new)
    end

    let!(:clear) do
      identity_map.clear
    end

    it "empties the identity map" do
      identity_map.should be_empty
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe ".clear" do

    before do
      described_class.set(Person.new)
    end

    let!(:clear) do
      described_class.clear
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe "#get" do

    context "normal model" do
      let!(:person) do
        Person.new
      end

      context "when getting by id" do

        context "when the document exists in the identity map" do

          before do
            identity_map.set(person)
          end

          let(:get) do
            identity_map.get(Person, person.id)
          end

          it "returns the matching person" do
            get.should eq(person)
          end
        end

        context "when the person does not exist in the map" do

          let(:get) do
            identity_map.get(Person, person.id)
          end

          it "returns nil" do
            get.should be_nil
          end
        end
      end

      context "when getting by an array of ids" do

        context "when the document exists in the identity map" do

          before do
            identity_map.set(person)
          end

          let(:get) do
            identity_map.get(Person, [ person.id ])
          end

          it "returns the matching documents" do
            get.should eq([ person ])
          end
        end

        context "when any id is not found in the map" do

          before do
            identity_map.set(person)
          end

          let(:get) do
            identity_map.get(Person, [ person.id, BSON::ObjectId.new ])
          end

          it "returns nil" do
            get.should be_nil
          end
        end
      end

      context "when getting by selector" do

        let!(:post_one) do
          Post.new(person: person)
        end

        let!(:post_two) do
          Post.new(person: person)
        end

        context "when there are documents in the map" do

          before do
            identity_map.set_many(post_one, person_id: person.id)
            identity_map.set_many(post_two, person_id: person.id)
          end

          let(:documents) do
            identity_map.get(Post, person_id: person.id)
          end

          it "returns the matching documents" do
            documents.should eq([ post_one, post_two ])
          end
        end

        context "when there are no documents in the map" do

          let(:documents) do
            identity_map.get(Post, person_id: person.id)
          end

          it "returns nil" do
            documents.should be_nil
          end
        end
      end
    end

    context "inherited class" do

      let!(:document) do
        Firefox.new
      end

      context "when getting by id" do

        context "when the document exists in the identity map" do

          before do
            identity_map.set(document)
          end

          it "returns the matching document by class" do
            get = identity_map.get(Firefox, document.id)
            get.should eq(document)
          end

          it "returns the matching document by superclass" do
            get = identity_map.get(Browser, document.id)
            get.should eq(document)
          end

          it "returns the matching document by class" do
            get = identity_map.get(Canvas, document.id)
            get.should eq(document)
          end
        end

        context "when the document does not exist in the map" do

          let(:get) do
            identity_map.get(Firefox, document.id)
          end

          it "returns nil" do
            get.should be_nil
          end
        end
      end
    end

    context "embedded class" do

      let!(:animal) do
        circus = Circus.new(animals: [ Animal.new(name: "Lion") ])
        circus.animals.first
      end

      context "when getting by id" do

        context "when the document exists in the identity map" do

          before do
            identity_map.set(animal)
          end

          let(:get) do
            identity_map.get(Animal, animal.id)
          end

          it "returns the matching document" do
            get.should eq(animal)
          end
        end

        context "when the document does not exist in the map" do

          let(:get) do
            identity_map.get(Animal, animal.id)
          end

          it "returns nil" do
            get.should be_nil
          end
        end
      end
    end
  end

  describe ".get" do

    let(:document) do
      Person.new
    end

    context "when the document exists in the identity map" do

      before do
        described_class.set(document)
      end

      let(:get) do
        described_class.get(Person, document.id)
      end

      it "returns the matching document" do
        get.should eq(document)
      end
    end

    context "when the document does not exist in the map" do

      let(:get) do
        described_class.get(Person, document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end

    context "when the mongoid identity map is disabled" do

      before do
        Mongoid.identity_map_enabled = false
      end

      after do
        Mongoid.identity_map_enabled = true
      end

      let(:get) do
        described_class.get(Person, document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end
  end

  describe "#remove" do

    let(:document) do
      Person.new
    end

    let!(:set) do
      identity_map.set(document)
    end

    context "when provided a document" do

      context "when the document has an id" do

        let!(:removed) do
          identity_map.remove(document)
        end

        it "deletes the document from the map" do
          identity_map.get(Person, document.id).should be_nil
        end

        it "returns the document" do
          removed.should eq(document)
        end
      end

      context "when the document has no id" do

        before do
          document.id = nil
        end

        let!(:removed) do
          identity_map.remove(document)
        end

        it "returns nil" do
          removed.should be_nil
        end
      end
    end

    context "when provided nil" do

      let!(:removed) do
        identity_map.remove(nil)
      end

      it "returns nil" do
        removed.should be_nil
      end
    end
  end

  describe "#set" do

    context "when setting a document" do

      context "when the identity map is enabled" do

        let(:document) do
          Person.new
        end

        let!(:set) do
          identity_map.set(document)
        end

        it "puts the object in the identity map" do
          identity_map.get(Person, document.id).should eq(document)
        end

        it "returns the document" do
          set.should eq(document)
        end
      end

      context "when the identity map is disabled" do

        before do
          Mongoid.identity_map_enabled = false
        end

        after do
          Mongoid.identity_map_enabled = true
        end

        let(:document) do
          Person.new
        end

        let!(:set) do
          identity_map.set(document)
        end

        it "does not put the object in the identity map" do
          identity_map.should be_empty
        end

        it "returns nil" do
          set.should be_nil
        end
      end
    end

    context "when setting a document with a nil id" do

      let(:document) do
        Person.new.tap do |person|
          person.id = nil
        end
      end

      let!(:set) do
        identity_map.set(document)
      end

      it "does not put the object in the identity map" do
        identity_map.get(nil, nil).should be_nil
      end

      it "returns nil" do
        set.should be_nil
      end
    end

    context "when setting nil" do

      let!(:set) do
        identity_map.set(nil)
      end

      it "places nothing in the map" do
        identity_map.should be_empty
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  describe "#set_many" do

    let!(:person) do
      Person.new
    end

    let!(:post_one) do
      Post.new(person: person)
    end

    let!(:post_two) do
      Post.new(person: person)
    end

    context "when no documents exist for the selector" do

      let!(:set) do
        identity_map.set_many(post_one, { person_id: person.id })
        identity_map.set_many(post_two, { person_id: person.id })
      end

      let(:documents) do
        identity_map[Post.collection_name][{ person_id: person.id }]
      end

      it "puts the documents in the map" do
        documents.should eq([ post_one, post_two ])
      end
    end
  end

  describe "#set_one" do

    let!(:person) do
      Person.new
    end

    let!(:post_one) do
      Post.new(person: person)
    end

    context "when no documents exist for the selector" do

      let!(:set) do
        identity_map.set_one(post_one, { person_id: person.id })
      end

      let(:document) do
        identity_map[Post.collection_name][{ person_id: person.id }]
      end

      it "puts the documents in the map" do
        document.should eq(post_one)
      end
    end
  end

  describe ".set" do

    context "when setting a document" do

      let(:document) do
        Person.new
      end

      let!(:set) do
        described_class.set(document)
      end

      it "puts the object in the identity map" do
        described_class.get(Person, document.id).should eq(document)
      end

      it "returns the document" do
        set.should eq(document)
      end
    end

    context "when setting nil" do

      let!(:set) do
        described_class.set(nil)
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  context "when accessing hash methods directly" do

    Hash.public_instance_methods(false).each do |method|

      it "can access #{method} at the class level" do
        described_class.should respond_to(method)
      end
    end
  end

  context "when executing in a fiber" do

    describe "#.get" do

      let(:document) do
        Person.new
      end

      let(:fiber) do
        Fiber.new do
          described_class.set(document)
          described_class.get(Person, document.id).should eq(document)
        end
      end

      it "gets the object from the identity map" do
        fiber.resume
      end
    end
  end
end
