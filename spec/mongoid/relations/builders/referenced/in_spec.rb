require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  let(:base) do
    stub
  end

  describe "#build" do

    let(:criteria) do
      Person.where(_id: object_id)
    end

    let(:metadata) do
      stub(
        klass: Person,
        name: :person,
        foreign_key: "person_id",
        criteria: criteria
      )
    end

    let(:builder) do
      described_class.new(base, metadata, object)
    end

    context "when provided an id" do

      context "when the object is an object id" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:object) do
          object_id
        end

        let(:person) do
          stub
        end

        before do
          criteria.expects(:first).returns(person)
        end

        let!(:document) do
          builder.build
        end

        it "sets the document" do
          document.should eq(person)
        end
      end

      context "when the object is an integer" do

        before do
          Person.field :_id, type: Integer
        end

        after do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new }
          )
        end

        let(:object_id) do
          666
        end

        let(:object) do
          object_id
        end

        let(:person) do
          stub
        end

        before do
          criteria.expects(:first).returns(person)
        end

        let!(:document) do
          builder.build
        end

        it "sets the document" do
          document.should eq(person)
        end
      end
    end

    context "when provided a object" do

      let(:object) do
        Person.new
      end

      let(:builder) do
        described_class.new(base, nil, object)
      end

      let(:document) do
        builder.build
      end

      it "returns the object" do
        document.should eq(object)
      end
    end
  end

  describe "#build" do

    let(:game) do
      Game.new
    end

    context "when no document found in the database" do

      context "when the id is nil" do

        it "returns nil" do
          game.person.should be_nil
        end
      end

      context "when the id is incorrect" do

        before do
          game.person_id = BSON::ObjectId.new
        end

        it "returns nil" do
          game.person.should be_nil
        end
      end
    end

    context "when the document is persisted" do

      before do
        Mongoid.identity_map_enabled = true
      end

      let!(:person) do
        Person.create
      end

      let(:game) do
        Game.new(person_id: person.id)
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      it "returns the document" do
        game.person.should eq(person)
      end

      it "gets the document from the identity map" do
        game.person.should equal(person)
      end
    end

    context 'setting an associated document to nil' do

      let(:person) do
        Person.create
      end

      let(:game) do
        Game.create(person: person)
      end

      before do
        game.person = nil
        game.save
      end

      it 'sets the person_id to nil' do
        game.person_id.should be_nil
      end

      it 'does not delete the person' do
        Person.find(person.id).should eq(person)
      end
    end
  end

  describe '#substitute' do

    let(:person) do
      Person.create
    end

    let(:game) do
      Game.create(person: person)
    end

    context 'setting an associated document to nil' do
      before do
        game.person = nil
      end

      it 'sets the person_id to nil' do
        game.person_id.should be_nil
      end

      it 'does not delete the person' do
        Person.find(person.id).should eq(person)
      end
    end

    context 'setting an associated document to nil' do

      let(:other_person) do
        Person.create
      end

      before do
        game.person = other_person
      end

      it 'sets the person_id to nil' do
        game.person_id.should eq(other_person.id)
      end

      it 'does not delete the person' do
        Person.find(person.id).should eq(person)
      end
    end
  end
end
