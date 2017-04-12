require "spec_helper"

describe Mongoid::Association::Referenced::HasOne::Builder do

  let(:base) do
    double(new_record?: false)
  end

  describe "#build" do

    let(:document) do
      association.build(base, object)
    end

    let(:association) do
      Mongoid::Association::Referenced::HasOne.new(Person, :post)
    end

    context "when provided an id" do

      let!(:post) do
        Post.create(person_id: object)
      end

      let(:object) do
        BSON::ObjectId.new
      end

      before do
        expect(Post).to receive(:where).with(association.foreign_key => object).and_call_original
      end

      it "sets the document" do
        expect(document).to eq(post)
      end
    end

    context "when provided a object" do

      let(:object) do
        Post.new
      end

      it "returns the object" do
        expect(document).to eq(object)
      end
    end

    context "when the document is not found" do

      let(:object) do
        BSON::ObjectId.new
      end

      it "returns nil" do
        expect(document).to be_nil
      end
    end

    context "when the document is persisted" do

      let(:person) do
        Person.create
      end

      let!(:game) do
        Game.create(person: person)
      end

      it "returns the document" do
        expect(person.game).to eq(game)
      end
    end

    context "when the document have a non standard pk" do

      let(:person) do
        Person.create
      end

      let!(:cat) do
        Cat.create(person: person)
      end

      it "returns the document" do
        expect(person.cat).to eq(cat)
      end
    end
  end
end
