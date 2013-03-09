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

  describe ".included" do

    let(:models) do
      Mongoid.models
    end

    let(:new_klass_name) do
      'NewKlassName'
    end

    let(:new_klass) do
      Class.new do
        class << self; attr_accessor :name; end
      end.tap{|new_klass| new_klass.name = new_klass_name}
    end

    let(:new_model) do
      new_klass.tap do
        new_klass.send(:include, ::Mongoid::Document)
      end
    end

    let(:twice_a_new_model) do
      new_klass.tap do
        2.times{ new_klass.send(:include, ::Mongoid::Document) }
      end
    end

    context "when Document has been included in a model" do
      it ".models should include that model" do
        models.should include(klass)
      end
    end

    context "before Document has been included" do
      it ".models should *not* include that model" do
        models.should_not include(new_klass)
      end
    end

    context "after Document has been included" do
      it ".models should include that model" do
        models.should include(new_model)
      end
    end

    context "after Document has been included multiple times" do
      it ".models should include that model just once" do
        models.count(twice_a_new_model).should be_eql(1)
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
        types.should eq([ "Address" ])
      end
    end

    context "when ._types had been called before class declaration" do
      let(:descendant) do
        Class.new(Person)
      end

      before do
        Person._types
        descendant
      end

      it "should clear descendants' cache" do
        Person._types.should include(descendant.to_s)
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

      context "without updated_at, with Timestamps" do

        before do
          document.updated_at = nil
        end

        it "has the id key name" do
          document.cache_key.should eq("dokuments/#{document.id}")
        end
      end

      context "without updated_at, without Timestamps" do
        let(:artist) do
          Artist.new
        end
        before do
          artist.save
        end

        it "should have the id key name" do
          artist.cache_key.should eq("artists/#{artist.id}")
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
      person.id.should be_a(Moped::BSON::ObjectId)
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
          Person.instantiate("_id" => Moped::BSON::ObjectId.new, "title" => "Sir")
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

  describe ".instantiate" do

    context "when passing a block" do

      let(:id) do
        Moped::BSON::ObjectId.new
      end

      let(:document) do
        Band.instantiate("_id" => id, "name" => "Depeche Mode") do |band|
          band.likes = 1000
        end
      end

      it "yields to the block" do
        document.likes.should eq(1000)
      end
    end

    context "when an id exists" do

      before do
        Mongoid.identity_map_enabled = true
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      let(:id) do
        Moped::BSON::ObjectId.new
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

  describe "#model_name" do

    let(:person) do
      Person.new
    end

    it "returns the class model name" do
      person.model_name.should eq("Person")
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

    context "when removing an embedded document" do

      before do
        person.save
        person.addresses.delete(address)
      end

      it "does not include the document in the hash" do
        person.as_document["addresses"].should be_empty
      end
    end

    context "when an embedded relation has been set to nil" do

      before do
        # Save the doc, then set an embeds_one relation to nil
        person.save
        person.name = nil
        person.save
      end

      it "does not include the document in the hash" do
        person.as_document.should_not have_key("name")
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
        Person.instantiate("_id" => Moped::BSON::ObjectId.new)
      end

      it "returns the id in an array" do
        person.to_key.should eq([ person.id ])
      end
    end

    context "when the document is destroyed" do

      let(:person) do
        Person.instantiate("_id" => Moped::BSON::ObjectId.new).tap do |peep|
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
        Person.instantiate("_id" => Moped::BSON::ObjectId.new)
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

  context "defining a Moped::BSON::ObjectId as a field" do

    let(:bson_id) do
      Moped::BSON::ObjectId.new
    end

    let(:person) do
      Person.new(bson_id: bson_id)
    end

    before do
      person.save
    end

    it "persists the correct type" do
      person.reload.bson_id.should be_a(Moped::BSON::ObjectId)
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

  describe "#becomes" do

    before(:all) do
      Person.validates_format_of(:ssn, without: /\$\$\$/)

      class Manager < Person
        field :level, type: Integer, default: 1
      end
    end

    after(:all) do
      Person.reset_callbacks(:validate)
      Object.send(:remove_const, :Manager)
    end

    context "when casting to a superclass" do

      let(:manager) do
        Manager.new(title: "Sir")
      end

      context "when no embedded documents are present" do

        let(:person) do
          manager.becomes(Person)
        end

        it "copies attributes" do
          person.title.should eq('Sir')
        end

        it "keeps the same object id" do
          person.id.should eq(manager.id)
        end

        it "sets the class type" do
          person._type.should eq("Person")
        end

        it "raises an error when inappropriate class is provided" do
          expect {
            manager.becomes(String)
          }.to raise_error(ArgumentError)
        end
      end

      context "when the document has embedded documents" do

        context "when the attribtues are protected" do

          let!(:appointment) do
            manager.appointments.build
          end

          let(:person) do
            manager.becomes(Person)
          end

          it "copies the embedded documents" do
            person.appointments.first.should eq(appointment)
          end

          it "returns new instances" do
            person.appointments.first.should_not equal(appointment)
          end
        end

        context "when the attributes are not protected" do

          context "when embedded doc is not persisted" do

            let!(:address) do
              manager.addresses.build(street: "hobrecht")
            end

            let(:person) do
              manager.becomes(Person)
            end

            it "copies the embedded documents" do
              person.addresses.first.should eq(address)
            end

            it "returns new instances" do
              person.addresses.first.should_not equal(address)
            end
          end

          context "when embedded doc is persisted" do

            let(:manager) do
              Manager.create(title: "Sir")
            end

            let!(:address) do
              manager.addresses.create(street: "hobrecht")
            end

            let(:person) do
              manager.becomes(Person)
            end

            before do
              person.save!
            end

            it "copies the embedded documents" do
              person.addresses.first.should eq(address)
            end

            it "copies the embedded documents only once" do
              person.reload.addresses.length.should eq(1)
            end
          end
        end
      end

      context "when the document has a localize field" do

        let(:manager) do
          Manager.new(title: "Sir", desc: "description")
        end

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the localize attribute" do
          person.desc.should eq("description")
        end
      end

      context "when the document is new" do

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the state" do
          person.should be_a_new_record
        end
      end

      context "when the document is persisted" do

        before do
          manager.save
        end

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the state" do
          person.should be_persisted
        end
      end

      context "when the document is destroyed" do

        before do
          manager.destroy
        end

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the state" do
          person.should be_destroyed
        end
      end

      context "when the document is dirty" do

        before do
          manager.save
          manager.ssn = "123-22-1234"
        end

        let(:person) do
          manager.becomes(Person)
        end

        it "copies over the dirty changes" do
          person.changes["ssn"].should eq([ nil, "123-22-1234" ])
        end

        it "adds the _type change" do
          person.changes["_type"].should eq([ "Manager", "Person" ])
        end
      end

      context "when the document is invalid" do

        before do
          manager.ssn = "$$$"
          manager.valid?
        end

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the errors" do
          person.errors.should include(:ssn)
        end
      end
    end

    context "when casting to a subclass" do

      let(:person) do
        Person.new(title: "Sir")
      end

      context "when no embedded documents are present" do

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies attributes" do
          manager.title.should eq('Sir')
        end

        it "keeps the same object id" do
          manager.id.should eq(person.id)
        end

        it "sets the class type" do
          manager._type.should eq("Manager")
        end

        it "raises an error when inappropriate class is provided" do
          expect {
            person.becomes(String)
          }.to raise_error(ArgumentError)
        end
      end

      context "when the document has embedded documents" do

        let!(:address) do
          person.addresses.build(street: "hobrecht")
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the embedded documents" do
          manager.addresses.first.should eq(address)
        end

        it "returns new instances" do
          manager.addresses.first.should_not equal(address)
        end
      end

      context "when the document is new" do

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the state" do
          manager.should be_a_new_record
        end
      end

      context "when the document is persisted" do

        before do
          person.save
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the state" do
          manager.should be_persisted
        end

        context "when downcasted document is saved" do

          before do
            manager.save
          end

          it "keeps the type" do
            manager.should be_an_instance_of(Manager)
          end

          it "can by queried by the parent class" do
            Person.find(manager.id).should be_an_instance_of(Manager)
          end

          it "can by queried by the main class" do
            Manager.find(manager.id).should be_an_instance_of(Manager)
          end
        end
      end

      context "when the document is destroyed" do

        before do
          person.destroy
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the state" do
          manager.should be_destroyed
        end
      end

      context "when the document is dirty" do

        before do
          person.save
          person.ssn = "123-22-1234"
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies over the dirty changes" do
          manager.changes["ssn"].should eq([ nil, "123-22-1234" ])
        end

        it "adds the _type change" do
          manager.changes["_type"].should eq([ "Person", "Manager" ])
        end
      end

      context "when the document is invalid" do

        before do
          person.ssn = "$$$"
          person.valid?
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the errors" do
          manager.errors.should include(:ssn)
        end
      end

      context "when the subclass has defaults" do

        let(:manager) do
          Person.new(title: 'Sir').becomes(Manager)
        end

        it "applies default attributes" do
          manager.level.should eq(1)
        end
      end
    end
  end

  context "when marshalling the document" do

    let(:person) do
      Person.new.tap do |person|
        person.addresses.extension
      end
    end

    let!(:account) do
      person.create_account(name: "savings")
    end

    describe Marshal, ".dump" do

      it "successfully dumps the document" do
        expect {
          Marshal.dump(person)
          Marshal.dump(account)
        }.not_to raise_error
      end
    end

    describe Marshal, ".load" do

      it "successfully loads the document" do
        expect { Marshal.load(Marshal.dump(person)) }.not_to raise_error
      end
    end
  end

  context "when putting a document in the cache" do

    describe ActiveSupport::Cache do

      let(:cache) do
        ActiveSupport::Cache::MemoryStore.new
      end

      describe "#fetch" do

        let!(:person) do
          Person.new
        end

        let!(:account) do
          person.create_account(name: "savings")
        end

        it "stores the parent object" do
          cache.fetch("key") { person }.should eq(person)
          cache.fetch("key").should eq(person)
        end

        it "stores the embedded object" do
          cache.fetch("key") { account }.should eq(account)
          cache.fetch("key").should eq(account)
        end
      end
    end
  end
end
