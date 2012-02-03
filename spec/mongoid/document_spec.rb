require "spec_helper"

describe Mongoid::Document do

  let(:klass) do
    Person
  end

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
        person.should_not eq(other)
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
            person.should_not eq(other)
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
            person.should eq(other)
          end
        end
      end

      context "when it has a different id" do

        let(:other) do
          Person.new
        end

        context "when the instances are the same" do

          it "returns true" do
            person.should eq(person)
          end
        end

        context "when the instances are different" do

          it "returns false" do
            person.should_not eq(other)
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
        Post.new(person: person).person
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

    context "when the comparable is an instance of a subclass" do

      it "returns true" do
        (Person === Doctor.new).should be_true
      end
    end
  end

  describe "#===" do

    context "when comparable is the same type" do

      context "when the instance is different" do

        it "returns false" do
          (person === Person.new).should be_false
        end
      end

      context "when the instance is the same" do

        it "returns true" do
          (person === person).should be_true
        end
      end
    end

    context "when the comparable is a subclass" do

      it "returns false" do
        (person === Doctor.new).should be_false
      end
    end

    context "when comparing to a class" do

      context "when the class is the same" do

        it "returns true" do
          (person === Person).should be_true
        end
      end

      context "when the class is a subclass" do

        it "returns false" do
          (person === Doctor).should be_false
        end
      end

      context "when the class is a superclass" do

        it "returns true" do
          (Doctor.new === Person).should be_true
        end
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
      (first <=> second ).should eq(-1)
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
        types.should eq([ "Address" ])
      end
    end
  end

  describe "#attributes" do

    let(:person) do
      Person.new(title: "Sir")
    end

    it "returns the attributes with indifferent access" do
      person[:title].should eq("Sir")
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

  describe "#cache_key" do

    let(:document) do
      Dokument.new
    end

    context "when the document is new" do

      it "has a new key name" do
        document.cache_key.should eq("dokuments/new")
      end
    end

    context "when persisted" do

      before do
        document.save
      end

      context "with updated_at" do

        let!(:updated_at) do
          document.updated_at.utc.to_s(:number)
        end

        it "has the id and updated_at key name" do
          document.cache_key.should eq("dokuments/#{document.id}-#{updated_at}")
        end
      end

      context "without updated_at" do

        before do
          document.updated_at = nil
        end

        it "has the id key name" do
          document.cache_key.should eq("dokuments/#{document.id}")
        end
      end
    end
  end

  describe "#identity" do

    let(:person) do
      Person.new
    end

    it "returns a [doc.class, doc.id] array" do
      person.identity.should eq([person.class, person.id])
    end
  end

  describe "#hash" do

    let(:person) do
      Person.new
    end

    it "returns the identity hash" do
      person.hash.should eq(person.identity.hash)
    end
  end

  describe "#initialize" do

    let(:person) do
      Person.new(title: "Sir")
    end

    it "sets persisted to false" do
      person.should_not be_persisted
    end

    it "creates an id for the document" do
      person.id.should be_a(BSON::ObjectId)
    end

    it "sets the attributes" do
      person.title.should eq("Sir")
    end

    context "when accessing a relation from an overridden setter" do

      let(:doctor) do
        Doctor.new(specialty: "surgery")
      end

      it "allows access to the relation" do
        doctor.users.first.should be_a(User)
      end

      it "properly allows super calls" do
        doctor.specialty.should eq("surgery")
      end
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
          person.title.should eq("Madam")
        end
      end

      context "when accessing relations" do

        let(:person) do
          Person.new(game: Game.new)
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
          person.game.name.should eq("Ms. Pacman")
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
          person.title.should eq("Madam")
        end
      end
    end

    context "when defaults are defined" do

      it "sets the default values" do
        person.age.should eq(100)
      end
    end

    context "when a block is provided" do

      let(:person) do
        Person.new do |doc|
          doc.title = "King"
        end
      end

      it "yields to the block" do
        person.title.should eq("King")
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
        person.title.should eq("Sir")
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
      Person.new(title: "Sir")
    end

    it "returns the internal attributes" do
      person.raw_attributes["title"].should eq("Sir")
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
      people.should eq([ person ])
    end
  end

  describe "#as_document" do

    let!(:person) do
      Person.new(title: "Sir")
    end

    let!(:address) do
      person.addresses.build(street: "Upper")
    end

    let!(:name) do
      person.build_name(first_name: "James")
    end

    let!(:location) do
      address.locations.build(name: "Home")
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

    context "with relation define store_as option in embeded_many" do

      let!(:phone) do
        person.phones.build(number: '+33123456789')
      end

      it 'includes the store_as key association' do
        person.as_document.should have_key("mobile_phones")
      end

      it 'should not include the key of association' do
        person.as_document.should_not have_key("phones")
      end
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
        person.to_key.should eq([ person.id ])
      end
    end

    context "when the document is destroyed" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new).tap do |peep|
          peep.destroyed = true
        end
      end

      it "returns the id in an array" do
        person.to_key.should eq([ person.id ])
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
        person.to_param.should eq(person.id.to_s)
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
        expect {
          person.title = "something"
        }.to_not raise_error
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
        person.freeze.should eq(person)
        expect { person.title = "something" }.to raise_error
      end
    end

    context "when frozen" do

      before do
        person.raw_attributes.freeze
      end

      it "keeps things frozen" do
        person.freeze
        expect {
          person.title = "something"
        }.to raise_error
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
  context "when a model name conflicts with a mongoid internal" do

    let(:scheduler) do
      Scheduler.new
    end

    it "allows the model name" do
      scheduler.strategy.should be_a(Strategy)
    end
  end

  describe "#initialize" do

    context "when providing a block" do

      it "sets the defaults before yielding" do
        Person.new do |person|
          person.age.should eq(100)
        end
      end
    end
  end

  context "defining a BSON::ObjectId as a field" do

    let(:bson_id) do
      BSON::ObjectId.new
    end

    let(:person) do
      Person.new(bson_id: bson_id)
    end

    before do
      person.save
    end

    it "persists the correct type" do
      person.reload.bson_id.should be_a(BSON::ObjectId)
    end

    it "has the correct value" do
      person.bson_id.should eq(bson_id)
    end
  end

  context "when setting bson id fields to empty strings" do

    let(:post) do
      Post.new
    end

    before do
      post.person_id = ""
    end

    it "converts them to nil" do
      post.person_id.should be_nil
    end
  end

  context "creating anonymous documents" do

    context "when defining collection" do

      let(:model) do
        Class.new do
          include Mongoid::Document
          store_in collection: "anonymous"
          field :gender
        end
      end

      it "allows the creation" do
        Object.const_set "Anonymous", model
      end
    end
  end

  context "becoming another class" do

    before(:all) do
      class Manager < Person
        field :level, type: Integer, default: 1
      end
    end

    %w{upcasting downcasting}.each do |context|

      before(:all) do
        Person.validates_format_of :ssn, without: /\$\$\$/
      end

      after(:all) do
        Person.reset_callbacks(:validate)
      end

      context "when #{context}" do

        if context == 'upcasting'

          let(:klass) do
            Manager
          end

          let(:to_become) do
            Person
          end
        else

          let(:klass) do
            Person
          end

          let(:to_become) do
            Manager
          end
        end

        let(:obj) do
          klass.new(title: 'Sir')
        end

        let(:became) do
          obj.becomes(to_become)
        end

        it "copies attributes" do
          became.title.should eq('Sir')
        end

        context "when the document is new" do

          it "copies the state" do
            became.should be_new_record
          end
        end

        context "when the document is persisted" do

          before do
            obj.save
          end

          it "copies the state" do
            became.should be_persisted
          end
        end

        context "when the document is destroyed" do

          before do
            obj.destroy
          end

          it "copies the state" do
            became.should be_destroyed
          end
        end

        context "when the document is invalid" do

          before do
            obj.ssn = "$$$"
            obj.valid?
          end

          it "copies the errors" do
            became.errors.should include(:ssn)
          end
        end

        it "sets the class type" do
          became._type.should eq(to_become.to_s)
        end

        it "raises an error when inappropriate class is provided" do
          expect {
            obj.becomes(String)
          }.to raise_error(ArgumentError)
        end
      end
    end

    context "upcasting to class with default attributes" do

      let(:obj) do
        Person.new(title: 'Sir').becomes(Manager)
      end

      it "applies default attributes" do
        obj.level.should eq(1)
      end
    end
  end

  context "when marshalling the document" do

    let(:person) do
      Person.new.tap do |person|
        person.addresses.extension
      end
    end

    describe Marshal, ".dump" do

      it "successfully dumps the document" do
        expect { Marshal.dump(person) }.not_to raise_error
      end
    end

    describe Marshal, ".load" do

      it "successfully loads the document" do
        expect { Marshal.load(Marshal.dump(person)) }.not_to raise_error
      end
    end
  end
end
