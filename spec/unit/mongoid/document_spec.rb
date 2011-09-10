require "spec_helper"

describe Mongoid::Document do

  let(:klass) { Person }

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

      context "when it has the same id" do

        context "when the classes are not the same" do

          let(:other) do
            Post.new
          end

          before do
            other.id = person.id
          end

          it "returns false" do
            person.should_not == other
          end
        end

        context "when the classes are the same" do

          let(:other) do
            Person.new
          end

          before do
            other.id = person.id
          end

          it "returns true" do
            person.should == other
          end
        end
      end

      context "when it has a different id" do

        let(:other) do
          Person.new
        end

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

  describe ".===" do

    context "when comparable is an instance of this document" do

      it "returns true" do
        (klass === person).should be_true
      end
    end

    context "when comparable is a relation of this document" do

      let(:relation) do
        Post.new(:person => person).person
      end

      it "returns true" do
        (klass === relation).should be_true
      end
    end

    context "when comparable is the same class" do

      it "returns true" do
        (klass === Person).should be_true
      end
    end

    context "when the comparable is a subclass" do

      it "returns false" do
        (Person === Doctor).should be_false
      end
    end
  end

  describe "#===" do

    context "when comparable is the same type" do

      it "returns true" do
        (person === Person.new).should be_true
      end
    end

    context "when the comparable is a subclass" do

      it "returns true" do
        (person === Doctor.new).should be_true
      end
    end
  end

  describe "#<=>" do

    let(:first) do
      Person.new
    end

    let(:second) do
      Person.new
    end

    it "compares based on the document id" do
      (first <=> second ).should == -1
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
      person[:title].should == "Sir"
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

      context "when accessing attributes" do

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

      context "when accessing relations" do

        let(:person) do
          Person.new(:game => Game.new)
        end

        before do
          Person.after_initialize do
            self.game.name = "Ms. Pacman"
          end
        end

        after do
          Person.reset_callbacks(:initialize)
        end

        it "runs the callbacks" do
          person.game.name.should == "Ms. Pacman"
        end
      end

      context "when instantiating model" do

        let(:person) do
          Person.instantiate("_id" => BSON::ObjectId.new, "title" => "Sir")
        end

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

      before do
        Mongoid.identity_map_enabled = true
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      let(:id) do
        BSON::ObjectId.new
      end

      let!(:person) do
        Person.instantiate("_id" => id, "title" => "Sir")
      end

      it "sets the attributes" do
        person.title.should == "Sir"
      end

      it "sets persisted to true" do
        person.should be_persisted
      end

      it "puts the document in the identity map" do
        Mongoid::IdentityMap.get(Person, id).should eq(person)
      end
    end

    context "when attributes are nil" do

      let(:person) do
        Person.instantiate
      end

      it "creates a new document" do
        person.should be_a(Person)
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

        after do
          Mongoid.raise_not_found_error = true
        end

        it "sets the attributes to empty" do
          person.reload.title.should be_nil
        end
      end
    end

    context "when a relation is set as nil" do

      before do
        person.instance_variable_set(:@name, nil)
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).
          with(:_id => person.id).returns({})
      end

      let(:reloaded) do
        person.reload
      end

      it "removes the instance variable" do
        reloaded.instance_variable_defined?(:@name).should be_false
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

  describe "#as_document" do

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
      person.as_document.should have_key("name")
    end

    it "includes embeds many attributes" do
      person.as_document.should have_key("addresses")
    end

    it "includes second level embeds many attributes" do
      person.as_document["addresses"].first.should have_key("locations")
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

  describe "#frozen?" do
    let(:person) do
      Person.new
    end

    context "when attributes are not frozen" do
      it "return false" do
        person.should_not be_frozen
        lambda { person.title = "something" }.should_not raise_error
      end
    end

    context "when attributes are frozen" do
      before do
        person.raw_attributes.freeze
      end
      it "return true" do
        person.should be_frozen
      end
    end
  end

  describe "#freeze" do
    let(:person) do
      Person.new
    end

    context "when not frozen" do

      it "freezes attributes" do
        person.freeze.should == person
        lambda { person.title = "something" }.should raise_error
      end
    end

    context "when frozen" do

      before do
        person.raw_attributes.freeze
      end

      it "keeps things frozen" do
        person.freeze
        lambda { person.title = "something" }.should raise_error
      end
    end
  end

  describe ".logger" do

    it "returns the mongoid logger" do
      Person.logger.should eq(Mongoid.logger)
    end
  end

  describe "#logger" do

    let(:person) do
      Person.new
    end

    it "returns the mongoid logger" do
      person.send(:logger).should eq(Mongoid.logger)
    end
  end

  context "after including the document module" do

    let(:movie) do
      Movie.new
    end

    it "resets to the global scope" do
      movie.global_set.should be_a(::Set)
    end
  end
end
