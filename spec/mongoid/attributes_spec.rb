require "spec_helper"

describe Mongoid::Attributes do

  describe "\#{attribute}" do

    context "when setting the value in the getter" do

      let(:account) do
        Account.new
      end

      it "does not cause an infinite loop" do
        expect(account.overridden).to eq("not recommended")
      end
    end

    context "when the attribute was excluded in a criteria" do

      let!(:person) do
        Person.create(title: "sir")
      end

      context "when the attribute is localized" do

        before do
          person.update_attribute(:desc, "test")
        end

        context "when the context includes" do

          context "when the attribute exists" do

            let(:from_db) do
              Person.only(:desc).first
            end

            it "does not raise an error" do
              expect(from_db.desc).to eq("test")
            end
          end

          context 'when the attribute is a hash field' do

            before do
              person.update_attribute(:map, map)
            end

            let(:map) do
              { 'dates' => { 'y' => { '2016' => 'Berlin' } } }
            end

            let(:from_db) do
              Person.only('map.dates.y.2016').first
            end

            it "does not raise an error" do
              expect(from_db.map).to eq(map)
            end
          end
        end

        context "when the context excludes" do

          context "when the attribute exists" do

            let(:from_db) do
              Person.without(:pets).first
            end

            it "does not raise an error" do
              expect(from_db.desc).to eq("test")
            end
          end
        end
      end

      context "when excluding with only" do

        let(:from_db) do
          Person.only(:_id).first
        end

        it "raises an error" do
          expect {
            from_db.title
          }.to raise_error(ActiveModel::MissingAttributeError)
        end
      end

      context "when excluding with without" do

        let(:from_db) do
          Person.without(:title).first
        end

        it "raises an error" do
          expect {
            from_db.title
          }.to raise_error(ActiveModel::MissingAttributeError)
        end
      end
    end
  end

  describe "#[]" do

    context "when the document is a new record" do

      let(:person) do
        Person.new
      end

      context "when accessing a localized field" do

        before do
          person.desc = "testing"
        end

        context "when passing just the name" do

          it "returns the full value" do
            expect(person[:desc]).to eq("en" => "testing")
          end
        end

        context "when passing the name with locale" do

          it "returns the value for the locale" do
            expect(person["desc.en"]).to eq("testing")
          end
        end
      end

      context "when attribute does not exist" do

        it "returns the default value" do
          expect(person[:age]).to eq(100)
        end
      end

      context "when attribute is not accessible" do

        before do
          person.owner_id = 5
        end

        it "returns the value" do
          expect(person[:owner_id]).to eq(5)
        end
      end
    end

    context "when the document is an existing record" do

      let!(:person) do
        Person.create(title: "sir")
      end

      context "when the attribute was excluded in a criteria" do

        context "when excluding with only" do

          let(:from_db) do
            Person.only(:_id).first
          end

          it "raises an error" do
            expect {
              from_db[:title]
            }.to raise_error(ActiveModel::MissingAttributeError)
          end
        end

        context "when excluding with without" do

          let(:from_db) do
            Person.without(:title).first
          end

          it "raises an error" do
            expect {
              from_db[:title]
            }.to raise_error(ActiveModel::MissingAttributeError)
          end
        end
      end

      context "when the attribute does not exist" do

        before do
          person.collection
            .find({ _id: person.id })
            .update_one({ "$unset" => { age: 1 }})
        end

        context "when found" do

          let(:found) do
            Person.find(person.id)
          end

          it "returns the default value" do
            expect(found[:age]).to eq(100)
          end
        end

        context "when reloaded" do

          before do
            Mongoid.raise_not_found_error = false
            person.reload
            Mongoid.raise_not_found_error = true
          end

          it "returns the default value" do
            expect(person[:age]).to eq(100)
          end
        end
      end
    end
  end

  describe "#[]=" do

    let(:person) do
      Person.new
    end

    context "when setting the attribute to nil" do

      let!(:age) do
        person[:age] = nil
      end

      it "does not use the default value" do
        expect(person.age).to be_nil
      end

      it "returns the set value" do
        expect(age).to be_nil
      end
    end

    context "when field has a default value" do

      let!(:terms) do
        person[:terms] = true
      end

      it "allows overwriting of the default value" do
        expect(person.terms).to be true
      end

      it "returns the set value" do
        expect(terms).to eq(true)
      end
    end
  end

  describe "#_id" do

    let(:person) do
      Person.new
    end

    it "delegates to #id" do
      expect(person._id).to eq(person.id)
    end

    context "when #id alias is overridden" do

      let(:object) do
        IdKey.new(key: 'foo')
      end

      it "delegates to another method" do
        expect(object.id).to eq(object.key)
      end
    end
  end

  describe "#_id=" do

    after(:all) do
      Person.field(
        :_id,
        type: BSON::ObjectId,
        pre_processed: true,
        default: ->{ BSON::ObjectId.new },
        overwrite: true
      )
    end

    context "when using object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new },
          overwrite: true
        )
      end

      let(:person) do
        Person.new
      end

      let(:bson_id) do
        BSON::ObjectId.new
      end

      context "when providing an object id" do

        before do
          person._id = bson_id
        end

        it "sets the id as the object id" do
          expect(person.id).to eq(bson_id)
        end
      end

      context "when providing a string" do

        before do
          person._id = bson_id.to_s
        end

        it "sets the id as the object id" do
          expect(person.id).to eq(bson_id)
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value to_s" do
          expect(person.id).to eq(2)
        end
      end

      context "when #id= alias is overridden" do

        let(:object) do
          IdKey.new(key: 'foo')
        end

        it "delegates to another method" do
          object.id = 'bar'
          expect(object.id).to eq('bar')
        end
      end

    end

    context "when using string ids" do

      before(:all) do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new.to_s },
          overwrite: true
        )
      end

      let(:person) do
        Person.new
      end

      let(:bson_id) do
        BSON::ObjectId.new
      end

      context "when providing an object id" do

        before do
          person._id = bson_id
        end

        it "sets the id as the string of the object id" do
          expect(person.id).to eq(bson_id.to_s)
        end
      end

      context "when providing a string" do

        before do
          person._id = bson_id.to_s
        end

        it "sets the id as the string" do
          expect(person.id).to eq(bson_id.to_s)
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value to_s" do
          expect(person.id).to eq("2")
        end
      end
    end

    context "when using integer ids" do

      before(:all) do
        Person.field(:_id, type: Integer, overwrite: true)
      end

      let(:person) do
        Person.new
      end

      context "when providing a string" do

        before do
          person._id = 1.to_s
        end

        it "sets the id as the integer" do
          expect(person.id).to eq(1)
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value" do
          expect(person.id).to eq(2)
        end
      end
    end
  end

  describe "#method_missing" do

    let(:attributes) do
      { testing: "Testing" }
    end

    let(:person) do
      Person.new(attributes)
    end

    context "when an attribute exists" do

      it "allows the getter" do
        expect(person.testing).to eq("Testing")
      end

      it "allows the setter" do
        person.testing = "Test"
        expect(person.testing).to eq("Test")
      end

      it "allows the getter before_type_cast" do
        expect(person.testing_before_type_cast).to eq("Testing")
      end

      it "returns true for respond_to?" do
        expect(person.respond_to?(:testing)).to be true
      end
    end

    context "when the provided value needs mongoization" do

      let(:new_years) do
        DateTime.new(2013, 1, 1, 0, 0, 0)
      end

      before do
        person[:new_years] = new_years
      end

      it "mongoizes the dynamic field" do
        expect(person.new_years).to be_a(Time)
      end

      it "keeps the same value" do
        expect(person.new_years).to eq(new_years)
      end
    end
  end

  describe "#process" do

    context "when attributes dont have fields defined" do

      let(:attributes) do
        {
          nofieldstring: "Testing",
          nofieldint: 5,
          employer: Employer.new
        }
      end

      context "when allowing dynamic fields" do

        let!(:person) do
          Person.new(attributes)
        end

        context "when attribute is a string" do

          it "adds the string to the attributes" do
            expect(person.attributes["nofieldstring"]).to eq("Testing")
          end
        end

        context "when attribute is not a string" do

          it "adds a cast value to the attributes" do
            expect(person.attributes["nofieldint"]).to eq(5)
          end
        end
      end

      context "when not allowing dynamic fields" do

        it "raises an unknown attribute error on instantiation" do
          expect {
            Account.new({ anothernew: "Test" })
          }.to raise_error(Mongoid::Errors::UnknownAttribute)
        end
      end
    end

    context "when supplied hash has string values" do

      let(:bson_id) do
        BSON::ObjectId.new
      end

      let!(:attributes) do
        {
          title: "value",
          age: "30",
          terms: "true",
          score: "",
          name: {
            _id: "2", first_name: "Test", last_name: "User"
          },
          addresses: [
            { _id: "3", street: "First Street" },
            { _id: "4", street: "Second Street" }
          ]
        }
      end

      let!(:person) do
        Person.new(attributes)
      end

      it "casts integers" do
        expect(person[:age]).to eq(30)
      end

      it "casts booleans" do
        expect(person[:terms]).to be true
      end

      it "sets empty strings to nil" do
        expect(person[:score]).to be_nil
      end
    end

    context "when associations provided in the attributes" do

      context "when association is a has_one" do

        let(:name) do
          Name.new(first_name: "Testy")
        end

        let(:attributes) do
          { name: name }
        end

        let(:person) do
          Person.new(attributes)
        end

        it "sets the associations" do
          expect(person.name).to eq(name)
        end
      end

      context "when association is a references_one" do

        let(:game) do
          Game.new(score: 100)
        end

        let(:attributes) do
          { game: game }
        end

        let!(:person) do
          Person.new(attributes)
        end

        it "sets the parent association" do
          expect(person.game).to eq(game)
        end

        it "sets the inverse association" do
          expect(game.person).to eq(person)
        end
      end

      context "when association is a embedded_in" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new(first_name: "Tyler", person: person)
        end

        it "sets the association" do
          expect(name.person).to eq(person)
        end
      end
    end

    context "when non-associations provided in the attributes" do

      let(:employer) do
        Employer.new
      end

      let(:attributes) do
        { employer_id: employer.id, title: "Sir" }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "calls the setter for the association" do
        expect(person.employer_id).to eq("1")
      end
    end

    context "when an empty array is provided in the attributes" do

      let(:attributes) do
        { aliases: [] }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "sets the empty array" do
        expect(person.aliases).to be_empty
      end
    end

    context "when an empty hash is provided in the attributes" do

      let(:attributes) do
        { map: {} }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "sets the empty hash" do
        expect(person.map).to eq({})
      end
    end

    context "when providing tainted parameters" do

      let(:params) do
        ActionController::Parameters.new(title: "sir")
      end

      it "raises an error" do
        expect {
          Person.new(params)
        }.to raise_error(ActiveModel::ForbiddenAttributesError)
      end
    end
  end

  context "updating when attributes already exist" do

    let(:person) do
      Person.new(title: "Sir")
    end

    let(:attributes) do
      { dob: "2000-01-01" }
    end

    before do
      person.process_attributes(attributes)
    end

    it "only overwrites supplied attributes" do
      expect(person.title).to eq("Sir")
    end
  end

  describe "#read_attribute" do

    context "when the document is a new record" do

      let(:person) do
        Person.new
      end

      context "when attribute does not exist" do

        it "returns the default value" do
          expect(person.age).to eq(100)
          expect(person.pets).to be false
        end

      end

      context "when attribute is not accessible" do

        before do
          person.owner_id = 5
        end

        it "returns the value" do
          expect(person.read_attribute(:owner_id)).to eq(5)
        end
      end
    end

    context "when the document is an existing record" do

      let(:person) do
        Person.create
      end

      context "when the attribute does not exist" do

        before do
          person.collection
            .find({ _id: person.id })
            .update_one({ "$unset" => { age: 1 }})
          Mongoid.raise_not_found_error = false
          person.reload
          Mongoid.raise_not_found_error = true
        end

        it "returns the default value" do
          expect(person.age).to eq(100)
        end
      end
    end

    context "when attribute has an aliased name" do

      let(:person) do
        Person.new
      end

      before(:each) do
        person.write_attribute(:t, "aliased field to test")
      end

      it "returns the value of the aliased field" do
        expect(person.read_attribute(:test)).to eq("aliased field to test")
      end
    end
  end

  describe "#read_attribute_before_type_cast" do

    let(:person) do
      Person.create
    end

    context "when the attribute has not yet been assigned" do

      it "returns the default value" do
        expect(person.age_before_type_cast).to eq(100)
      end
    end

    context "after the attribute has been assigned" do

      it "returns the default value" do
        person.age = "old"
        expect(person.age_before_type_cast).to eq("old")
      end
    end
  end

  describe "#attribute_present?" do

    context "when document is a new record" do

      let(:person) do
        Person.new
      end

      context "when attribute does not exist" do

        it "returns false" do
          expect(person.attribute_present?(:owner_id)).to be false
        end
      end

      context "when attribute does exist" do
        before do
          person.owner_id = 5
        end

        it "returns true" do
          expect(person.attribute_present?(:owner_id)).to be true
        end
      end
    end

    context "when the document is an existing record" do

      let(:person) do
        Person.create
      end

      context "when the attribute does not exist" do

        before do
          person.collection
            .find({ _id: person.id })
            .update_one({ "$unset" => { age: 1 }})
          Mongoid.raise_not_found_error = false
          person.reload
          Mongoid.raise_not_found_error = true
        end

        it "returns true" do
          expect(person.attribute_present?(:age)).to be true
        end
      end
    end

    context "when the value is boolean" do

      let(:person) do
        Person.new
      end

      context "when attribute does not exist" do

        context "when the value is true" do

          it "return true"  do
            person.terms = false
            expect(person.attribute_present?(:terms)).to be true
          end
        end

        context "when the value is false" do

          it "return true"  do
            person.terms = false
            expect(person.attribute_present?(:terms)).to be true
          end
        end
      end
    end

    context "when the value is blank string" do

      let(:person) do
        Person.new(title: '')
      end

      it "return false" do
        expect(person.attribute_present?(:title)).to be false
      end
    end

    context "when the attribute is not on only list" do

      before { Person.create }
      let(:person) do
        Person.only(:id).first
      end

      it "return false" do
        expect(person.attribute_present?(:foobar)).to be false
      end
    end
  end

  describe "#has_attribute?" do

    let(:person) do
      Person.new(title: "sir")
    end

    context "when the key is in the attributes" do

      context "when provided a symbol" do

        it "returns true" do
          expect(person.has_attribute?(:title)).to be true
        end
      end

      context "when provided a string" do

        it "returns true" do
          expect(person.has_attribute?("title")).to be true
        end
      end
    end

    context "when the key is not in the attributes" do

      it "returns false" do
        expect(person.has_attribute?(:employer_id)).to be false
      end
    end
  end

  describe '#has_attribute_before_type_cast?' do

    let(:person) do
      Person.new
    end

    context "before the attribute has been assigned" do

      it "returns false" do
        expect(person.has_attribute_before_type_cast?(:age)).to be false
      end
    end

    context "after the attribute has been assigned" do

      it "returns true" do
        person.age = 'old'
        expect(person.has_attribute_before_type_cast?(:age)).to be true
      end
    end
  end

  describe "#remove_attribute" do

    context "when the attribute exists" do

      let(:person) do
        Person.create(title: "Sir")
      end

      before do
        person.remove_attribute(:title)
      end

      it "removes the attribute" do
        expect(person.title).to be_nil
      end

      it "removes the key from the attributes hash" do
        expect(person.has_attribute?(:title)).to be false
      end

      context "when saving after the removal" do

        before do
          person.save
        end

        it "persists the removal" do
          expect(person.reload.has_attribute?(:title)).to be false
        end
      end
    end

    context "when the attribute exists in embedded document" do

     let(:pet) do
       Animal.new(name: "Cat")
     end

     let(:person) do
       Person.new(pet: pet)
     end

     before do
       person.save
       person.pet.remove_attribute(:name)
     end

     it "removes the attribute" do
       expect(person.pet.name).to be_nil
     end

     it "removes the key from the attributes hash" do
       expect(person.pet.has_attribute?(:name)).to be false
     end

     context "when saving after the removal" do

       before do
         person.save
       end

       it "persists the removal" do
         expect(person.reload.pet.has_attribute?(:name)).to be false
       end
     end

    end

    context "when the attribute does not exist" do

      let(:person) do
        Person.new
      end

      before do
        person.remove_attribute(:title)
      end

      it "does not fail" do
        expect(person.title).to be_nil
      end
    end

    context "when the document is new" do

      let(:person) do
        Person.new(title: "sir")
      end

      before do
        person.remove_attribute(:title)
      end

      it "does not add a delayed unset operation" do
        expect(person.delayed_atomic_unsets).to be_empty
      end
    end
  end

  describe "#respond_to?" do

    context "when allowing dynamic fields" do

      let(:person) do
        Person.new
      end

      context "when asking for the getter" do

        context "when the attribute exists" do

          before do
            person[:attr] = "test"
          end

          it "returns true" do
            expect(person).to respond_to(:attr)
          end
        end

        context "when the attribute does not exist" do

          it "returns false" do
            expect(person).to_not respond_to(:attr)
          end
        end
      end

      context "when asking for the setter" do

        context "when the attribute exists" do

          before do
            person[:attr] = "test"
          end

          it "returns true" do
            expect(person).to respond_to(:attr=)
          end
        end

        context "when the attribute does not exist" do

          it "returns false" do
            expect(person).to_not respond_to(:attr=)
          end
        end
      end
    end

    context "when not allowing dynamic fields" do

      let(:bar) do
        Bar.new
      end

      context "when asking for the getter" do

        it "returns false" do
          expect(bar).to_not respond_to(:attr)
        end
      end

      context "when asking for the setter" do

        it "returns false" do
          expect(bar).to_not respond_to(:attr=)
        end
      end
    end
  end

  describe "#write_attribute" do

    context "when attribute does not exist" do

      let(:person) do
        Person.new
      end

      it "returns the default value" do
        expect(person.age).to eq(100)
      end
    end

    context "when setting an attribute that needs type casting" do
      let(:person) do
        Person.new(age: "old")
      end

      it "should store the attribute before type cast" do
        expect(person.age_before_type_cast).to eq("old")
      end
    end

    context "when setting the attribute to nil" do

      let(:person) do
        Person.new(age: nil)
      end

      it "does not use the default value" do
        expect(person.age).to be_nil
      end
    end

    context "when field has a default value" do

      let(:person) do
        Person.new
      end

      before do
        person.terms = true
      end

      it "allows overwriting of the default value" do
        expect(person.terms).to be true
      end
    end

    context "when attribute has an aliased name" do

      let(:person) do
        Person.new
      end

      before(:each) do
        person.write_attribute(:test, "aliased field to test")
      end

      it "allows the field name to be udpated" do
        expect(person.t).to eq("aliased field to test")
      end
    end

    context "when attribute is a Hash" do
      let(:person) { Person.new map: { somekey: "somevalue" } }

      it "raises an error when try to set an invalid value" do
        expect {
          person.map = []
        }.to raise_error(Mongoid::Errors::InvalidValue)
      end

      it "can set a Hash value" do
        expect(person.map).to eq( { somekey: "somevalue" } )
      end
    end

    context "when attribute is an Array" do
      let(:person) { Person.new aliases: [ :alias_1 ] }

      it "can set an Array Value" do
        expect(person.aliases).to eq([ :alias_1 ])
      end

      it "raises an error when try to set an invalid value" do
        expect {
          person.aliases = {}
        }.to raise_error(Mongoid::Errors::InvalidValue)
      end
    end

    context "when attribute is localized and #attributes is a BSON::Document" do
      let(:dictionary) { Dictionary.new }

      before do
        allow(dictionary).to receive(:attributes).and_return(BSON::Document.new)
      end

      it "sets the value for the current locale" do
        dictionary.write_attribute(:description, 'foo')
        expect(dictionary.description).to eq('foo')
      end
    end
  end

  describe "#typed_value_for" do

    let(:person) do
      Person.new
    end

    context "when the key has been specified as a field" do

      it "retuns the typed value" do
        person.send(:typed_value_for, "age", "51")
      end
    end

    context "when the key has not been specified as a field" do

      before do
        allow(person).to receive(:fields).and_return({})
      end

      it "returns the value" do
        person.send(:typed_value_for, "age", expect("51")).to eq("51")
      end
    end
  end

  describe "#apply_default_attributes" do

    let(:person) do
      Person.new
    end

    it "typecasts proc values" do
      expect(person.age).to eq(100)
    end
  end

  [:attributes=, :write_attributes].each do |method|

    describe "##{method}" do

      context "when nested" do

        let(:person) do
          Person.new
        end

        before do
          person.send(method, { videos: [{title: "Fight Club"}] })
        end

        it "sets nested documents" do
          expect(person.videos.first.title).to eq("Fight Club")
        end
      end

      context "typecasting" do

        let(:person) do
          Person.new
        end

        let(:attributes) do
          { age: "50" }
        end

        context "when passing a hash" do

          before do
            person.send(method, attributes)
          end

          it "properly casts values" do
            expect(person.age).to eq(50)
          end
        end

        context "when passing nil" do

          before do
            person.send(method, nil)
          end

          it "does not set anything" do
            expect(person.age).to eq(100)
          end
        end
      end

      context "copying from instance" do

        let(:person) do
          Person.new
        end

        let(:instance) do
          Person.new(attributes)
        end

        let(:attributes) do
          { age: 50, range: 1..100 }
        end

        before do
          person.send(method, instance.attributes)
        end

        it "properly copies values" do
          expect(person.age).to eq(50)
        end

        it "properly copies ranges" do
          expect(person.range).to eq(1..100)
        end
      end

      context "on a parent document" do

        context "when the parent has a has many through a has one" do

          let(:owner) do
            PetOwner.new(title: "Mr")
          end

          let(:pet) do
            Pet.new(name: "Fido")
          end

          let(:vet_visit) do
            VetVisit.new(date: Date.today)
          end

          before do
            owner.pet = pet
            pet.vet_visits = [ vet_visit ]
            owner.send(method, { pet: { name: "Bingo" } })
          end

          it "does not overwrite child attributes if not in the hash" do
            expect(owner.pet.name).to eq("Bingo")
            expect(owner.pet.vet_visits.size).to eq(1)
          end
        end

        context "when parent destroy all child on setter" do

          let(:owner) do
            PetOwner.create!(title: "Mr")
          end

          let(:pet) do
            Pet.create!(name: "Kika", pet_owner: owner)
          end

          let!(:vet_visit) do
            pet.vet_visits.create!(date: Date.today)
          end

          before do
            pet.send(method, { visits_count: 3 })
            pet.save!
          end

          it "has 3 new entries" do
            expect(pet.vet_visits.count).to eq(3)
          end

          it "persists the changes" do
            expect(pet.reload.vet_visits.count).to eq(3)
          end
        end

        context "when the parent has an empty embeds_many" do

          let(:person) do
            Person.new
          end

          let(:attributes) do
            { services: [] }
          end

          it "does not raise an error" do
            person.send(method, attributes)
          end
        end
      end

      context "on a child document" do

        context "when child is part of a has one" do

          let(:person) do
            Person.new(title: "Sir", age: 30)
          end

          let(:name) do
            Name.new(first_name: "Test", last_name: "User")
          end

          before do
            person.name = name
            name.send(method, first_name: "Test2", last_name: "User2")
          end

          it "sets the child attributes on the parent" do
            expect(name.attributes).to eq(
              { "_id" => "Test-User", "first_name" => "Test2", "last_name" => "User2" }
            )
          end
        end

        context "when child is part of a has many" do

          let(:person) do
            Person.new(title: "Sir")
          end

          let(:address) do
            Address.new(street: "Test")
          end

          before do
            person.addresses << address
            address.send(method, "street" => "Test2")
          end

          it "updates the child attributes on the parent" do
            expect(address.attributes).to eq(
              { "_id" => "test", "street" => "Test2" }
            )
          end
        end
      end
    end
  end

  describe "#alias_attribute" do

    let(:product) do
      Product.new
    end

    context "when checking against the alias" do

      before do
        product.cost = 500
      end

      it "adds the alias for criteria" do
        expect(Product.where(cost: 500).selector).to eq("price" => 500)
      end

      it "aliases the getter" do
        expect(product.cost).to eq(500)
      end

      it "aliases the existence check" do
        expect(product.cost?).to be true
      end

      it "aliases *_changed?" do
        expect(product.cost_changed?).to be true
      end

      it "aliases *_change" do
        expect(product.cost_change).to eq([ nil, 500 ])
      end

      it "aliases *_will_change!" do
        expect(product).to respond_to(:cost_will_change!)
      end

      it "aliases *_was" do
        expect(product.cost_was).to be_nil
      end

      it "aliases reset_*!" do
        product.reset_cost!
        expect(product.cost).to be_nil
      end

      it "aliases *_before_type_cast" do
        product.cost = "expensive"
        expect(product.cost_before_type_cast).to eq("expensive")
      end
    end

    context "when checking against the original" do

      before do
        product.price = 500
      end

      it "aliases the getter" do
        expect(product.price).to eq(500)
      end

      it "aliases the existence check" do
        expect(product.price?).to be true
      end

      it "aliases *_changed?" do
        expect(product.price_changed?).to be true
      end

      it "aliases *_change" do
        expect(product.price_change).to eq([ nil, 500 ])
      end

      it "aliases *_will_change!" do
        expect(product).to respond_to(:price_will_change!)
      end

      it "aliases *_was" do
        expect(product.price_was).to be_nil
      end

      it "aliases reset_*!" do
        product.reset_price!
        expect(product.price).to be_nil
      end
    end
  end

  context "when persisting nil attributes" do

    let!(:person) do
      Person.create(score: nil)
    end

    it "has an entry in the attributes" do
      expect(person.reload.attributes).to have_key("score")
    end
  end

  context "with a default last_drink_taken_at" do

    let(:person) do
      Person.new
    end

    it "saves the default" do
      expect { person.save }.to_not raise_error
      expect(person.last_drink_taken_at).to eq(1.day.ago.in_time_zone("Alaska").to_date)
    end
  end

  context "when default values are defined" do

    context "when no value exists in the database" do

      let(:person) do
        Person.create
      end

      it "applies the default value" do
        expect(person.last_drink_taken_at).to eq(1.day.ago.in_time_zone("Alaska").to_date)
      end
    end

    context "when a value exists in the database" do

      context "when the value is not nil" do

        let!(:person) do
          Person.create(age: 50)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "does not set the default" do
          expect(from_db.age).to eq(50)
        end
      end

      context "when the value is explicitly nil" do

        let!(:person) do
          Person.create(age: nil)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "does not set the default" do
          expect(from_db.age).to be_nil
        end
      end

      context "when the default is a proc" do

        let!(:account) do
          Account.create(name: "savings", balance: "100")
        end

        let(:from_db) do
          Account.find(account.id)
        end

        it "applies the defaults after all attributes are set" do
          expect(from_db).to be_balanced
        end
      end
    end
  end

  context 'when calling the attribute check method' do

    context 'when the attribute is localized' do
      let(:person) do
        Person.create(desc: 'localized')
      end

      before do
        person.desc = nil
      end

      it 'applies the localization when checking the attribute' do
        expect(person.desc?).to be(false)
      end

      context 'when the field is a boolean' do

        before do
          person.desc = false
        end

        it 'applies the localization when checking the attribute' do
          expect(person.desc?).to be(false)
        end
      end
    end

    context 'when the attribute is not localized' do
      let(:person) do
        Person.create(username: 'localized')
      end

      before do
        person.username = nil
      end

      it 'does not apply localization when checking the attribute' do
        expect(person.name?).to be(false)
      end
    end
  end
end
