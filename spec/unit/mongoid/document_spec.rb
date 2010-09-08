require "spec_helper"

describe Mongoid::Document do

  let(:person) do
    Person.new
  end

  it "does not respond to _destroy" do
    person.should_not respond_to(:_destroy)
  end

  describe "#==" do

    context "when comparable is not a document" do

      let(:other) do
        "Document"
      end

      it "returns false" do
        person.should_not == other
      end
    end

    context "when comparable is a document" do

      let(:other) do
        Person.new
      end

      context "when it has the same id" do

        before do
          other.id = person.id
        end

        it "returns true" do
          person.should == other
        end
      end

      context "when it has a different id" do

        context "when the instances are the same" do

          it "returns true" do
            person.should == person
          end
        end

        context "when the instances are different" do

          it "returns false" do
            person.should_not == other
          end
        end
      end
    end
  end

  describe "._types" do

    context "when the document is subclassed" do

      let(:types) do
        Person._types
      end

      it "includes the root" do
        types.should include("Person")
      end

      it "includes the subclasses" do
        types.should include("Doctor")
      end
    end

    context "when the document is not subclassed" do

      let(:types) do
        Address._types
      end

      it "returns the document" do
        types.should == [ "Address" ]
      end
    end
  end

  describe "#attributes" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    it "returns the attributes with indifferent access" do
      person.attributes[:title].should == "Sir"
    end
  end

  describe "#clone" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    context "when versions exist" do

      let(:cloned) do
        person.clone
      end

      before do
        person[:versions] = [ { :number => 1 } ]
      end

      it "returns a new document" do
        cloned.should_not be_persisted
      end

      it "has an id" do
        cloned.id.should_not be_nil
      end

      it "has a different id from the original" do
        cloned.id.should_not == person.id
      end

      it "does not clone the versions" do
        cloned[:versions].should be_nil
      end
    end
  end

  describe "#eql?" do

    context "when comparable is not a document" do

      let(:other) do
        "Document"
      end

      it "returns false" do
        person.should_not be_eql(other)
      end
    end

    context "when comparable is a document" do

      let(:other) do
        Person.new
      end

      context "when it has the same id" do

        before do
          other.id = person.id
        end

        it "returns true" do
          person.should be_eql(other)
        end
      end

      context "when it has a different id" do

        context "when the instances are the same" do

          it "returns true" do
            person.should be_eql(person)
          end
        end

        context "when the instances are different" do

          it "returns false" do
            person.should_not be_eql(other)
          end
        end
      end
    end
  end

  describe "#hash" do

    let(:person) do
      Person.new
    end

    it "returns the id hash" do
      person.hash.should == person.id.hash
    end
  end

  describe "#identify" do

    let!(:person) do
      Person.new
    end

    let!(:identifier) do
      stub
    end

    before do
      Mongoid::Identity.expects(:new).with(person).returns(identifier)
    end

    it "creates a new identity" do
      identifier.expects(:create)
      person.identify
    end
  end

  describe "#initialize" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    it "sets persisted to false" do
      person.should_not be_persisted
    end

    it "creates an id for the document" do
      person.id.should be_a(BSON::ObjectId)
    end

    it "sets the attributes" do
      person.title.should == "Sir"
    end

    context "when initialize callbacks are defined" do

      before do
        Person.set_callback :initialize, :after do |doc|
          doc.title = "Madam"
        end
      end

      after do
        Person.reset_callbacks(:initialize)
      end

      it "runs the callbacks" do
        person.title.should == "Madam"
      end
    end

    context "when defaults are defined" do

      it "sets the default values" do
        person.age.should == 100
      end
    end

    context "when a block is provided" do

      let(:person) do
        Person.new do |doc|
          doc.title = "King"
        end
      end

      it "yields to the block" do
        person.title.should == "King"
      end
    end
  end

  describe "#.instantiate" do

    context "when an id exists" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new, "title" => "Sir")
      end

      it "sets the attributes" do
        person.title.should == "Sir"
      end

      it "sets persisted to true" do
        person.should be_persisted
      end
    end

    context "when attributes are nil" do

      let(:person) do
        Person.instantiate
      end

      it "creates a new document" do
        person.should be_a(Person)
      end

      it "creates an id" do
        person.id.should be_a(BSON::ObjectId)
      end
    end
  end

  describe "#raw_attributes" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    it "returns the internal attributes" do
      person.raw_attributes["title"].should == "Sir"
    end
  end

  describe "#reload" do

    let(:collection) do
      stub
    end

    let(:person) do
      Person.new(:title => "Sir")
    end

    let!(:name) do
      person.build_name(:first_name => "James")
    end

    context "when the document has been persisted" do

      let(:reloaded) do
        person.reload
      end

      let!(:attributes) do
        {
          "title" => "Mrs",
          "name" => { "first_name" => "Money" }
        }
      end

      before do
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).
          with(:_id => person.id).returns(attributes)
      end

      it "reloads the attributes" do
        reloaded.title.should == "Mrs"
      end

      it "reloads the relations" do
        reloaded.name.first_name.should == "Money"
      end
    end

    context "when the document is new" do

      before do
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).
          with(:_id => person.id).returns(nil)
      end

      context "when raising a not found error" do

        before do
          Mongoid.raise_not_found_error = true
        end

        after do
          Mongoid.raise_not_found_error = false
        end

        it "raises an error" do
          expect {
            person.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when not raising a not found error" do

        before do
          Mongoid.raise_not_found_error = false
        end

        it "sets the attributes to empty" do
          person.reload.title.should be_nil
        end
      end
    end
  end

  describe "#remove_child" do

    let(:person) do
      Person.new
    end

    context "when child is an embeds one" do

      let!(:name) do
        person.build_name(:first_name => "James")
      end

      before do
        person.remove_child(name)
      end

      it "removes the relation instance" do
        person.name.should be_nil
      end
    end

    context "when child is an embeds many" do

      let!(:address) do
        person.addresses.build(:street => "Upper St")
      end

      before do
        person.remove_child(address)
      end

      it "removes the document from the relation target" do
        person.addresses.should be_empty
      end
    end
  end

  describe "#to_a" do

    let(:person) do
      Person.new
    end

    let(:people) do
      person.to_a
    end

    it "returns the document in an array" do
      people.should == [ person ]
    end
  end

  describe "#to_hash" do

    let!(:person) do
      Person.new(:title => "Sir")
    end

    let!(:address) do
      person.addresses.build(:street => "Upper")
    end

    let!(:name) do
      person.build_name(:first_name => "James")
    end

    let!(:location) do
      address.locations.build(:name => "Home")
    end

    it "includes embeds one attributes" do
      person.to_hash.should have_key("name")
    end

    it "includes embeds many attributes" do
      person.to_hash.should have_key("addresses")
    end

    it "includes second level embeds many attributes" do
      person.to_hash["addresses"].first.should have_key("locations")
    end
  end

  describe "#to_key" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      it "returns nil" do
        person.to_key.should be_nil
      end
    end

    context "when the document is not new" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns the id in an array" do
        person.to_key.should == [ person.id ]
      end
    end
  end

  describe "#to_param" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      it "returns nil" do
        person.to_param.should be_nil
      end
    end

    context "when the document is not new" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns the id as a string" do
        person.to_param.should == person.id.to_s
      end
    end
  end
end
