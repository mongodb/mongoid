require "spec_helper"

describe Mongoid::Document do

  let(:klass) do
    Person
  end

  let(:person) do
    Person.new
  end

  it "does not respond to _destroy" do
    expect(person).to_not respond_to(:_destroy)
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
        expect(models).to include(klass)
      end
    end

    context "before Document has been included" do
      it ".models should *not* include that model" do
        expect(models).to_not include(new_klass)
      end
    end

    context "after Document has been included" do
      it ".models should include that model" do
        expect(models).to include(new_model)
      end
    end

    context "after Document has been included multiple times" do
      it ".models should include that model just once" do
        expect(models.count(twice_a_new_model)).to be_eql(1)
      end
    end
  end

  describe "._types" do

    context "when the document is subclassed" do

      let(:types) do
        Person._types
      end

      it "includes the root" do
        expect(types).to include("Person")
      end

      it "includes the subclasses" do
        expect(types).to include("Doctor")
      end
    end

    context "when the document is not subclassed" do

      let(:types) do
        Address._types
      end

      it "returns the document" do
        expect(types).to eq([ "Address" ])
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
        expect(Person._types).to include(descendant.to_s)
      end
    end
  end

  describe "#attributes" do

    let(:person) do
      Person.new(title: "Sir")
    end

    it "returns the attributes with indifferent access" do
      expect(person[:title]).to eq("Sir")
    end
  end

  describe "#cache_key" do

    let(:document) do
      Dokument.new
    end

    context "when the document is new" do

      it "has a new key name" do
        expect(document.cache_key).to eq("dokuments/new")
      end
    end

    context "when persisted" do

      before do
        document.save
      end

      context "with updated_at" do

        let!(:updated_at) do
          document.updated_at.utc.to_s(:nsec)
        end

        it "has the id and updated_at key name" do
          expect(document.cache_key).to eq("dokuments/#{document.id}-#{updated_at}")
        end
      end

      context "without updated_at, with Timestamps" do

        before do
          document.updated_at = nil
        end

        it "has the id key name" do
          expect(document.cache_key).to eq("dokuments/#{document.id}")
        end
      end
    end

    context "when model dont have Timestamps" do

      let(:artist) do
        Artist.create!
      end

      it "should have the id key name" do
        expect(artist.cache_key).to eq("artists/#{artist.id}")
      end
    end

    context "when model has Short Timestamps" do

      let(:agent) do
        ShortAgent.create!
      end

      let!(:updated_at) do
        agent.updated_at.utc.to_s(:nsec)
      end

      it "has the id and updated_at key name" do
        expect(agent.cache_key).to eq("short_agents/#{agent.id}-#{updated_at}")
      end
    end
  end

  describe "#identity" do

    let(:person) do
      Person.new
    end

    it "returns a [doc.class, doc.id] array" do
      expect(person.identity).to eq([person.class, person.id])
    end
  end

  describe "#hash" do

    let(:person) do
      Person.new
    end

    it "returns the identity hash" do
      expect(person.hash).to eq(person.identity.hash)
    end
  end

  describe "#initialize" do

    let(:person) do
      Person.new(title: "Sir")
    end

    it "sets persisted to false" do
      expect(person).to_not be_persisted
    end

    it "creates an id for the document" do
      expect(person.id).to be_a(BSON::ObjectId)
    end

    it "sets the attributes" do
      expect(person.title).to eq("Sir")
    end

    context "when the model has a default scope" do

      context "when the default scope is settable" do

        let(:sound) do
          Sound.new
        end

        it "sets the default scoping on the model" do
          expect(sound).to be_active
        end
      end

      context "when the default scope is not settable" do

        let(:audio) do
          Audio.new
        end

        it "does not set the default scoping" do
          expect(audio.attributes.except('_id')).to be_empty
        end
      end
    end

    context "when accessing a relation from an overridden setter" do

      let(:doctor) do
        Doctor.new(specialty: "surgery")
      end

      it "allows access to the relation" do
        expect(doctor.users.first).to be_a(User)
      end

      it "properly allows super calls" do
        expect(doctor.specialty).to eq("surgery")
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
          expect(person.title).to eq("Madam")
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
          expect(person.game.name).to eq("Ms. Pacman")
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
          expect(person.title).to eq("Madam")
        end
      end
    end

    context "when defaults are defined" do

      it "sets the default values" do
        expect(person.age).to eq(100)
      end
    end

    context "when a block is provided" do

      let(:person) do
        Person.new do |doc|
          doc.title = "King"
        end
      end

      it "yields to the block" do
        expect(person.title).to eq("King")
      end
    end
  end

  describe ".instantiate" do

    context "when passing a block" do

      let(:id) do
        BSON::ObjectId.new
      end

      let(:document) do
        Band.instantiate("_id" => id, "name" => "Depeche Mode") do |band|
          band.likes = 1000
        end
      end

      it "yields to the block" do
        expect(document.likes).to eq(1000)
      end
    end

    context "when an id exists" do

      let(:id) do
        BSON::ObjectId.new
      end

      let!(:person) do
        Person.instantiate("_id" => id, "title" => "Sir")
      end

      it "sets the attributes" do
        expect(person.title).to eq("Sir")
      end

      it "sets persisted to true" do
        expect(person).to be_persisted
      end
    end

    context "when attributes are nil" do

      let(:person) do
        Person.instantiate
      end

      it "creates a new document" do
        expect(person).to be_a(Person)
      end
    end
  end

  describe "#model_name" do

    let(:person) do
      Person.new
    end

    it "returns the class model name" do
      expect(person.model_name).to eq("Person")
    end
  end

  describe "#raw_attributes" do

    let(:person) do
      Person.new(title: "Sir")
    end

    it "returns the internal attributes" do
      expect(person.raw_attributes["title"]).to eq("Sir")
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
      expect(people).to eq([ person ])
    end
  end

  describe "#as_json" do

    let!(:person) do
      Person.new(title: "Sir")
    end

    context "when no options are provided" do

      it "does not apply any options" do
        expect(person.as_json["title"]).to eq("Sir")
        expect(person.as_json["age"]).to eq(100)
      end

      context "when options for the super method are provided" do

        let(:options) do
          { only: :title }
        end

        it "passes the options through to the super method" do
          expect(person.as_json(options)["title"]).to eq("Sir")
          expect(person.as_json(options).keys).not_to include("age")
        end
      end
    end

    context "when the Mongoid-specific options are provided" do

      let(:options) do
        { compact: true }
      end

      it "applies the Mongoid-specific options" do
        expect(person.as_json(options)["title"]).to eq("Sir")
        expect(person.as_json(options)["age"]).to eq(100)
        expect(person.as_json(options).keys).not_to include("lunch_time")
      end

      context "when options for the super method are provided" do

        let(:options) do
          { compact: true, only: [:title, :pets, :ssn] }
        end

        it "passes the options through to the super method" do
          expect(person.as_json(options)["title"]).to eq("Sir")
          expect(person.as_json(options)["pets"]).to eq(false)
        end

        it "applies the Mongoid-specific options" do
          expect(person.as_json(options).keys).not_to include("ssn")
        end
      end
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
      expect(person.as_document).to have_key("name")
    end

    it "includes embeds many attributes" do
      expect(person.as_document).to have_key("addresses")
    end

    it "includes second level embeds many attributes" do
      expect(person.as_document["addresses"].first).to have_key("locations")
    end

    context "with relation define store_as option in embeded_many" do

      let!(:phone) do
        person.phones.build(number: '+33123456789')
      end

      it 'includes the store_as key association' do
        expect(person.as_document).to have_key("mobile_phones")
      end

      it 'should not include the key of association' do
        expect(person.as_document).to_not have_key("phones")
      end
    end

    context "when removing an embedded document" do

      before do
        person.save
        person.addresses.delete(address)
      end

      it "does not include the document in the hash" do
        expect(person.as_document["addresses"]).to be_empty
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
        expect(person.as_document).to_not have_key("name")
      end
    end
  end

  describe "#to_key" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      it "returns nil" do
        expect(person.to_key).to be_nil
      end
    end

    context "when the document is not new" do

      let(:person) do
        Person.create!
      end

      it "returns the id in an array" do
        expect(person.to_key).to eq([ person.id.to_s ])
      end

      it "can query using the key" do
        expect(person.id).to eq Person.find(person.to_key).first.id
      end
    end

    context "when the document is destroyed" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new).tap do |peep|
          peep.destroyed = true
        end
      end

      it "returns the id in an array" do
        expect(person.to_key).to eq([ person.id.to_s ])
      end
    end
  end

  describe "#to_param" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      it "returns nil" do
        expect(person.to_param).to be_nil
      end
    end

    context "when the document is not new" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns the id as a string" do
        expect(person.to_param).to eq(person.id.to_s)
      end
    end
  end

  describe "#frozen?" do

    let(:person) do
      Person.new
    end

    context "when attributes are not frozen" do

      it "return false" do
        expect(person).to_not be_frozen
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
        expect(person).to be_frozen
      end
    end
  end

  describe "#freeze" do

    let(:person) do
      Person.new
    end

    context "when freezing the model" do

      context "when not frozen" do

        it "freezes attributes" do
          expect(person.freeze).to eq(person)
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

    context "when freezing attributes of the model" do

      context "when assigning a frozen value" do

        context "when the frozen value is a hash" do

          let(:hash) do
            {"foo" => {"bar" => {"baz" => [1,2,3]}}}
          end

          let(:assign_hash) do
            person.map = hash.freeze
          end

          it "no mutation occurs during assignment" do
            expect{ assign_hash }.not_to raise_error
          end
        end
      end
    end
  end

  describe ".logger" do

    it "returns the mongoid logger" do
      expect(Person.logger).to eq(Mongoid.logger)
    end
  end

  describe "#logger" do

    let(:person) do
      Person.new
    end

    it "returns the mongoid logger" do
      expect(person.send(:logger)).to eq(Mongoid.logger)
    end
  end

  context "after including the document module" do

    let(:movie) do
      Movie.new
    end

    it "resets to the global scope" do
      expect(movie.global_set).to be_a(::Set)
    end
  end
  context "when a model name conflicts with a mongoid internal" do

    let(:scheduler) do
      Scheduler.new
    end

    it "allows the model name" do
      expect(scheduler.strategy).to be_a(Strategy)
    end
  end

  describe "#initialize" do

    context "when providing a block" do

      it "sets the defaults before yielding" do
        Person.new do |person|
          expect(person.age).to eq(100)
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
      expect(person.reload.bson_id).to be_a(BSON::ObjectId)
    end

    it "has the correct value" do
      expect(person.bson_id).to eq(bson_id)
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
      expect(post.person_id).to be_nil
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
          expect(person.title).to eq('Sir')
        end

        it "keeps the same object id" do
          expect(person.id).to eq(manager.id)
        end

        it "sets the class type" do
          expect(person._type).to eq("Person")
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
            expect(person.appointments.first).to eq(appointment)
          end

          it "returns new instances" do
            expect(person.appointments.first).to_not equal(appointment)
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
              expect(person.addresses.first).to eq(address)
            end

            it "returns new instances" do
              expect(person.addresses.first).to_not equal(address)
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
              expect(person.addresses.first).to eq(address)
            end

            it "copies the embedded documents only once" do
              expect(person.reload.addresses.length).to eq(1)
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
          expect(person.desc).to eq("description")
        end
      end

      context "when the document is new" do

        let(:person) do
          manager.becomes(Person)
        end

        it "copies the state" do
          expect(person).to be_a_new_record
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
          expect(person).to be_persisted
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
          expect(person).to be_destroyed
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
          expect(person.changes["ssn"]).to eq([ nil, "123-22-1234" ])
        end

        it "adds the _type change" do
          expect(person.changes["_type"]).to eq([ "Manager", "Person" ])
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
          expect(person.errors).to include(:ssn)
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
          expect(manager.title).to eq('Sir')
        end

        it "keeps the same object id" do
          expect(manager.id).to eq(person.id)
        end

        it "sets the class type" do
          expect(manager._type).to eq("Manager")
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
          expect(manager.addresses.first).to eq(address)
        end

        it "returns new instances" do
          expect(manager.addresses.first).to_not equal(address)
        end
      end

      context "when the document is new" do

        let(:manager) do
          person.becomes(Manager)
        end

        it "copies the state" do
          expect(manager).to be_a_new_record
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
          expect(manager).to be_persisted
        end

        context "when downcasted document is saved" do

          before do
            manager.save
          end

          it "keeps the type" do
            expect(manager).to be_an_instance_of(Manager)
          end

          it "copies over the dirty changes" do
            expect(manager.changes["ssn"]).to eq(person.changes["ssn"])
          end

          it "can by queried by the parent class" do
            expect(Person.find(manager.id)).to be_an_instance_of(Manager)
          end

          it "can by queried by the main class" do
            expect(Manager.find(manager.id)).to be_an_instance_of(Manager)
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
          expect(manager).to be_destroyed
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
          expect(manager.changes["ssn"]).to eq([ nil, "123-22-1234" ])
        end

        it "adds the _type change" do
          expect(manager.changes["_type"]).to eq([ "Person", "Manager" ])
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
          expect(manager.errors).to include(:ssn)
        end

      end

      context "when the subclass validates attributes not present on the parent class" do

        before do
          Manager.validates_inclusion_of(:level, in: [1, 2])
        end

        let(:manager) do
          person.becomes(Manager)
        end

        it "validates the instance of the subclass" do
          manager.level = 3
          expect(manager.valid?).to be false
        end
      end

      context "when the subclass has defaults" do

        let(:manager) do
          Person.new(title: 'Sir').becomes(Manager)
        end

        it "applies default attributes" do
          expect(manager.level).to eq(1)
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
          expect(cache.fetch("key") { person }).to eq(person)
          expect(cache.fetch("key")).to eq(person)
        end

        it "stores the embedded object" do
          expect(cache.fetch("key") { account }).to eq(account)
          expect(cache.fetch("key")).to eq(account)
        end
      end
    end
  end
end
