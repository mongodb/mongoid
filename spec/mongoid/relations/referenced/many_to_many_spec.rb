require "spec_helper"

describe Mongoid::Relations::Referenced::ManyToMany do

  before(:all) do
    Mongoid.raise_not_found_error = true
    Person.autosaved_relations.delete_one(:preferences)
    Person.autosave(Person.relations["preferences"].merge!(autosave: true))
    Person.synced(Person.relations["preferences"])
  end

  after(:all) do
    Person.reset_callbacks(:save)
    Person.reset_callbacks(:destroy)
  end

  [ :<<, :push, :concat ].each do |method|

    describe "##{method}" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let!(:preference) do
          Preference.new
        end

        let(:result) do
          person.preferences.send(method, preference)
        end

        it "returns an array of loaded documents" do
          result.should eq([ preference ])
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let!(:preference) do
          Preference.new
        end

        let(:result) do
          person.preferences.send(method, preference)
        end

        it "returns an array of loaded documents" do
          result.should eq([ preference ])
        end
      end

      context "when the relations are not polymorphic" do

        context "when the inverse relation is not defined" do

          let(:person) do
            Person.new
          end

          let(:house) do
            House.new
          end

          before do
            person.houses << house
          end

          it "appends the document to the relation" do
            person.houses.should eq([ house ])
          end

          it "sets the foreign key on the relation" do
            person.house_ids.should eq([ house.id ])
          end
        end

        context "when appending in a parent create block" do

          let!(:preference) do
            Preference.create(name: "testing")
          end

          let!(:person) do
            Person.create do |doc|
              doc.preferences << preference
            end
          end

          it "adds the documents to the relation" do
            person.preferences.should eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "saves the target" do
            preference.should be_persisted
          end

          it "adds the correct number of documents" do
            person.preferences.size.should eq(1)
          end

          it "persists the link" do
            person.reload.preferences.should eq([ preference ])
          end
        end

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          context "when the child is new" do

            let(:preference) do
              Preference.new
            end

            before do
              person.preferences.send(method, preference)
            end

            it "adds the documents to the relation" do
              person.preferences.should eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              person.preference_ids.should eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              preference.person_ids.should eq([ person.id ])
            end

            it "does not save the target" do
              preference.should be_new_record
            end

            it "adds the correct number of documents" do
              person.preferences.size.should eq(1)
            end

            context "when appending a second time" do

              before do
                person.preferences.send(method, preference)
              end

              it "allows the document to be added again" do
                person.preferences.should eq([ preference, preference ])
              end

              it "allows duplicate ids" do
                person.preference_ids.should eq([ preference.id, preference.id ])
              end
            end
          end

          context "when the child is already persisted" do

            let!(:persisted) do
              Preference.create(name: "testy")
            end

            let(:preference) do
              Preference.first
            end

            before do
              person.preferences.send(method, preference)
              person.save
            end

            it "adds the documents to the relation" do
              person.preferences.should eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              person.preference_ids.should eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              preference.person_ids.should eq([ person.id ])
            end

            it "saves the target" do
              preference.should be_persisted
            end

            it "adds the correct number of documents" do
              person.preferences.size.should eq(1)
            end

            it "persists the link" do
              person.reload.preferences.should eq([ preference ])
            end
          end

          context "when setting via the associated ids" do

            let!(:persisted) do
              Preference.create(name: "testy")
            end

            let(:preference) do
              Preference.first
            end

            let(:person) do
              Person.new(preference_ids: [ preference.id ])
            end

            before do
              person.save
            end

            it "adds the documents to the relation" do
              person.preferences.should eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              person.preference_ids.should eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              preference.reload.person_ids.should eq([ person.id ])
            end

            it "adds the correct number of documents" do
              person.preferences.size.should eq(1)
            end

            it "persists the link" do
              person.reload.preferences.should eq([ preference ])
            end
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create
          end

          let(:preference) do
            Preference.new
          end

          before do
            person.preferences.send(method, preference)
          end

          it "adds the documents to the relation" do
            person.preferences.should eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "sets the base on the inverse relation" do
            preference.people.should eq([ person ])
          end

          it "sets the same instance on the inverse relation" do
            preference.people.first.should eql(person)
          end

          it "saves the target" do
            preference.should_not be_new_record
          end

          it "adds the document to the target" do
            person.preferences.count.should eq(1)
          end

          context "when documents already exist on the relation" do

            let(:preference_two) do
              Preference.new
            end

            before do
              person.preferences.send(method, preference_two)
            end

            it "adds the documents to the relation" do
              person.preferences.should eq([ preference, preference_two ])
            end

            it "sets the foreign key on the relation" do
              person.preference_ids.should eq([ preference.id, preference_two.id ])
            end

            it "sets the foreign key on the inverse relation" do
              preference_two.person_ids.should eq([ person.id ])
            end

            it "sets the base on the inverse relation" do
              preference_two.people.should eq([ person ])
            end

            it "sets the same instance on the inverse relation" do
              preference_two.people.first.should eql(person)
            end

            it "saves the target" do
              preference.should_not be_new_record
            end

            it "adds the document to the target" do
              person.preferences.count.should eq(2)
            end
          end
        end

        context "when both sides have been persisted" do

          let(:person) do
            Person.create
          end

          let(:event) do
            Event.create
          end

          before do
            person.administrated_events << event
          end

          it "sets the front side of the relation" do
            person.administrated_events.should eq([ event ])
          end

          it "sets the inverse side of the relation" do
            event.administrators.should eq([ person ])
          end

          context "when reloading" do

            it "sets the front side of the relation" do
              person.reload.administrated_events.should eq([ event ])
            end

            it "sets the inverse side of the relation" do
              event.reload.administrators.should eq([ person ])
            end
          end

          context "when performing a new database query" do

            let(:loaded_person) do
              Person.find(person.id)
            end

            let(:loaded_event) do
              Event.find(event.id)
            end

            it "sets the front side of the relation" do
              loaded_person.administrated_events.should eq([ event ])
            end

            it "sets the inverse side of the relation" do
              loaded_event.administrators.should eq([ person ])
            end
          end
        end

        context "when the relation also includes a has_many relation" do

          let(:artwork) do
            Artwork.create
          end

          let(:exhibition) do
            Exhibition.create
          end

          let(:exhibitor) do
            Exhibitor.create(exhibition: exhibition)
          end

          before do
            artwork.exhibitors << exhibitor
          end

          it "creates a single artwork object" do
            Artwork.count.should eq(1)
          end
        end

        context "when the relation is self referencing" do

          let(:tag_one) do
            Tag.create(text: "one")
          end

          let(:tag_two) do
            Tag.create(text: "two")
          end

          before do
            tag_one.related << tag_two
          end

          it "sets the front side of the relation" do
            tag_one.related.should eq([ tag_two ])
          end

          it "sets the inverse side of the relation" do
            tag_two.related.should eq([ tag_one ])
          end

          context "when reloading" do

            it "sets the front side of the relation" do
              tag_one.reload.related.should eq([ tag_two ])
            end

            it "sets the inverse side of the relation" do
              tag_two.reload.related.should eq([ tag_one ])
            end
          end

          context "when performing a new database query" do

            let(:loaded_tag_one) do
              Tag.find(tag_one.id)
            end

            let(:loaded_tag_two) do
              Tag.find(tag_two.id)
            end

            it "sets the front side of the relation" do
              loaded_tag_one.related.should eq([ tag_two ])
            end

            it "sets the inverse side of the relation" do
              loaded_tag_two.related.should eq([ tag_one ])
            end
          end
        end
      end
    end
  end

  describe "#=" do

    context "when trying to add duplicate entries" do

      let(:person) do
        Person.new
      end

      let(:preference) do
        Preference.create(name: "one")
      end

      before do
        person.preferences = [ preference, preference ]
      end

      context "when the document is new" do

        it "does not add the duplicates" do
          person.preferences.should eq([ preference ])
        end

        it "does not create duplicate keys" do
          person.preference_ids.should eq([ preference.id ])
        end
      end

      context "when the document is persisted" do

        before do
          person.save
        end

        it "does not add the duplicates" do
          person.preferences.should eq([ preference ])
        end

        it "does not create duplicate keys" do
          person.preference_ids.should eq([ preference.id ])
        end

        it "does not add duplicates on the inverse" do
          preference.people.should eq([ person ])
        end

        it "does not add duplicate inverse keys" do
          preference.person_ids.should eq([ person.id ])
        end
      end
    end

    context "when the relation is not polymorphic" do

      context "when the parent and relation are new records" do

        let(:person) do
          Person.new
        end

        let(:preference) do
          Preference.new
        end

        before do
          person.preferences = [ preference ]
        end

        it "sets the relation" do
          person.preferences.should eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          person.preference_ids.should eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          preference.person_ids.should eq([ person.id ])
        end

        it "does not save the target" do
          preference.should be_new_record
        end
      end

      context "when the parent is new but the relation exists" do

        let(:person) do
          Person.new
        end

        let!(:preference) do
          Preference.create
        end

        before do
          person.preferences = [ preference ]
        end

        it "sets the relation" do
          person.preferences.should eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          person.preference_ids.should eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          preference.person_ids.should eq([ person.id ])
        end

        context "and the parent is persisted" do

          before do
            person.save!
            preference.reload
          end

          it "maintains the relation" do
            person.preferences.should eq([ preference ])
          end

          it "maintains the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "maintains the foreign key on the inverse relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "maintains the base on the inverse relation" do
            preference.people.first.should eq(person)
          end
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let(:preference) do
          Preference.new
        end

        before do
          person.preferences = [ preference ]
        end

        it "sets the relation" do
          person.preferences.should eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          person.preference_ids.should eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          preference.person_ids.should eq([ person.id ])
        end

        it "sets the base on the inverse relation" do
          preference.people.first.should eq(person)
        end

        it "saves the target" do
          preference.should be_persisted
        end

        it "persists the relation" do
          person.reload.preferences == [ preference ]
        end

        context "when overwriting an existing relation" do

          let(:another_preference) do
            Preference.new
          end

          before do
            person.preferences = [ another_preference ]
          end

          it "sets the relation" do
            person.preferences.should eq([ another_preference ])
          end

          it "saves the target" do
            another_preference.should be_persisted
          end

          it "does not leave foreign keys of the previous relation" do
            person.preference_ids.should eq([ another_preference.id ])
          end

          it "clears its own key on the foreign relation" do
            preference.person_ids.should be_empty
          end

          context "and person reloaded instead of saved" do

            before do
              person.reload
              another_preference.reload
            end

            it "persists the relation between person and another_preference" do
              person.preferences.should eq([ another_preference ])
            end

            it "persists the relation between another_prefrence and person" do
              another_preference.people.should eq([ person ])
            end

            it "no longer has any relation between preference and person" do
              preference.people.should be_empty
            end
          end

          context "and person is saved" do

            before do
              person.save
              person.reload
              another_preference.reload
            end

            it "persists the relation between person and another_preference" do
              person.preferences.should eq([ another_preference ])
            end

            it "persists the relation between another_prefrence and person" do
              another_preference.people.should eq([ person ])
            end

            it "no longer has any relation between preference and person" do
              preference.people.should be_empty
            end
          end
        end
      end
    end
  end

  [ nil, [] ].each do |value|

    describe "#= #{value}" do

      context "when the relation is not polymorphic" do

        context "when the inverse relation is not defined" do

          let(:person) do
            Person.new
          end

          let(:house) do
            House.new
          end

          before do
            person.houses << house
            person.houses = value
          end

          it "clears the relation" do
            person.houses.should be_empty
          end

          it "clears the foreign keys" do
            person.house_ids.should be_empty
          end
        end

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          let(:preference) do
            Preference.new
          end

          before do
            person.preferences = [ preference ]
            person.preferences = value
          end

          it "sets the relation to an empty array" do
            person.preferences.should be_empty
          end

          it "removed the inverse relation" do
            preference.people.should be_empty
          end

          it "removes the foreign key values" do
            person.preference_ids.should be_empty
          end

          it "removes the inverse foreign key values" do
            preference.person_ids.should be_empty
          end
        end

        context "when the parent is not a new record" do

          context "when the relation has been loaded" do

            let(:person) do
              Person.create
            end

            let(:preference) do
              Preference.new
            end

            before do
              person.preferences = [ preference ]
              person.preferences = value
            end

            it "sets the relation to an empty array" do
              person.preferences.should be_empty
            end

            it "removed the inverse relation" do
              preference.people.should be_empty
            end

            it "removes the foreign key values" do
              person.preference_ids.should be_empty
            end

            it "removes the inverse foreign key values" do
              preference.person_ids.should be_empty
            end

            it "does not delete the target from the database" do
              preference.should_not be_destroyed
            end
          end

          context "when the relation has not been loaded" do

            let(:preference) do
              Preference.new
            end

            let(:person) do
              Person.create.tap do |p|
                p.preferences = [ preference ]
              end
            end

            let!(:from_db) do
              Person.find(person.id)
            end

            before do
              from_db.preferences = value
            end

            it "sets the relation to an empty array" do
              from_db.preferences.should be_empty
            end

            it "removes the foreign key values" do
              from_db.preference_ids.should be_empty
            end
          end
        end
      end
    end
  end

  [ :build, :new ].each do |method|

    describe "##{method}" do

      context "when providing scoped mass assignment" do

        let(:person) do
          Person.new
        end

        let(:house) do
          person.houses.send(
            method,
            { name: "Dream", model: "Home" }, as: :admin
          )
        end

        it "sets the attributes for the provided role" do
          house.name.should eq("Dream")
        end

        it "does not set the attributes for other roles" do
          house.model.should be_nil
        end
      end

      context "when the relation is not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          let!(:preference) do
            person.preferences.send(method, name: "settings")
          end

          it "adds the document to the relation" do
            person.preferences.should eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "sets the inverse foreign key on the relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "sets the attributes" do
            preference.name.should eq("settings")
          end

          it "does not save the target" do
            preference.should be_new_record
          end

          it "adds the correct number of documents" do
            person.preferences.size.should eq(1)
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create
          end

          let!(:preference) do
            person.preferences.send(method, name: "settings")
          end

          it "adds the document to the relation" do
            person.preferences.should eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "sets the inverse foreign key on the relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "sets the base on the inverse relation" do
            preference.people.should eq([ person ])
          end

          it "sets the attributes" do
            preference.name.should eq("settings")
          end

          it "does not save the target" do
            preference.should be_new_record
          end

          it "adds the correct number of documents" do
            person.preferences.size.should eq(1)
          end

          context "when saving the target" do

            before do
              preference.save
            end

            it "persists the parent keys" do
              person.reload.preference_ids.should eq([ preference.id ])
            end
          end
        end
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::ManyToMany
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(extension?: false)
    end

    it "returns the embedded in builder" do
      described_class.builder(nil, metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe "#clear" do

    context "when the relation is not polymorphic" do

      context "when the parent has been persisted" do

        let!(:person) do
          Person.create
        end

        context "when the children are persisted" do

          let!(:preference) do
            person.preferences.create(name: "settings")
          end

          let!(:relation) do
            person.preferences.clear
          end

          it "clears out the relation" do
            person.preferences.should be_empty
          end

          it "removes the parent from the inverse relation" do
            preference.people.should_not include(person)
          end

          it "removes the foreign keys" do
            person.preference_ids.should be_empty
          end

          it "removes the parent key from the inverse" do
            preference.person_ids.should_not include(person.id)
          end

          it "does not delete the documents" do
            preference.should_not be_destroyed
          end

          it "persists the nullification" do
            person.reload.preferences.should be_empty
          end

          it "returns the relation" do
            relation.should be_empty
          end
        end

        context "when the children are not persisted" do

          let!(:preference) do
            person.preferences.build(name: "setting")
          end

          let!(:relation) do
            person.preferences.clear
          end

          it "clears out the relation" do
            person.preferences.should be_empty
          end
        end
      end

      context "when the parent is not persisted" do

        let(:person) do
          Person.new
        end

        let!(:preference) do
          person.preferences.build(name: "setting")
        end

        let!(:relation) do
          person.preferences.clear
        end

        it "clears out the relation" do
          person.preferences.should be_empty
        end
      end
    end
  end

  describe "#count" do

    let(:person) do
      Person.create
    end

    context "when documents have been persisted" do

      let!(:preference) do
        person.preferences.create(name: "setting")
      end

      it "returns the number of persisted documents" do
        person.preferences.count.should eq(1)
      end
    end

    context "when appending to a loaded relation" do

      let!(:preference) do
        person.preferences.create(name: "setting")
      end

      before do
        person.preferences.count
        person.preferences << Preference.create(name: "two")
      end

      it "returns the number of persisted documents" do
        person.preferences.count.should eq(2)
      end
    end

    context "when documents have not been persisted" do

      let!(:preference) do
        person.preferences.build(name: "settings")
      end

      it "returns 0" do
        person.preferences.count.should eq(0)
      end
    end

    context "when new documents exist in the database" do

      context "when the documents are part of the relation" do

        before do
          Preference.create(person_ids: [ person.id ])
        end

        it "returns the count from the db" do
          person.reload.preferences.count.should eq(1)
        end
      end

      context "when the documents are not part of the relation" do

        before do
          Preference.create
        end

        it "returns the count from the db" do
          person.preferences.count.should eq(0)
        end
      end
    end

    context "when the inverse relation is not defined" do

      context "when documents have been persisted" do

        let!(:house) do
          person.houses.create(name: "Wayne Manor")
        end

        it "returns the number of persisted documents" do
          person.houses.count.should eq(1)
        end
      end

      context "when documents have not been persisted" do

        let!(:house) do
          person.houses.build(name: "Ryugyong Hotel")
        end

        it "returns 0" do
          person.preferences.count.should eq(0)
        end
      end
    end
  end

  [ :create, :create! ].each do |method|

    describe "##{method}" do

      context "when providing scoped mass assignment" do

        let(:person) do
          Person.create
        end

        let(:house) do
          person.houses.send(
            method,
            { name: "Dream", model: "Home" }, as: :admin
          )
        end

        it "sets the attributes for the provided role" do
          house.name.should eq("Dream")
        end

        it "does not set the attributes for other roles" do
          house.model.should be_nil
        end
      end

      context "when the relation is not polymorphic" do

        context "when using string keys" do

          let(:agent) do
            Agent.create(number: "007")
          end

          before do
            agent.accounts.create(name: "testing again")
          end

          it "does not convert the string key to an object id" do
            agent.account_ids.should eq([ "testing-again" ])
          end
        end

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          it "raises an unsaved document error" do
            expect {
              person.preferences.send(method, name: "Testing")
            }.to raise_error(Mongoid::Errors::UnsavedDocument)
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.send(method)
          end

          let!(:preference) do
            person.preferences.send(method, name: "Testing")
          end

          it "sets the foreign key on the relation" do
            person.preference_ids.should eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            preference.person_ids.should eq([ person.id ])
          end

          it "adds the document" do
            person.preferences.should eq([ preference ])
          end

          it "sets the base on the inverse relation" do
            preference.people.should eq([ person ])
          end

          it "sets the attributes" do
            preference.name.should eq("Testing")
          end

          it "saves the target" do
            preference.should be_persisted
          end

          it "adds the document to the target" do
            person.preferences.count.should eq(1)
          end

          it "does not duplicate documents" do
            person.reload.preferences.count.should eq(1)
          end

          it "does not duplicate ids" do
            person.reload.preference_ids.count.should eq(1)
          end
        end
      end
    end
  end

  describe "#create!" do

    context "when validation fails" do

      let(:person) do
        Person.create
      end

      context "when the relation is not polymorphic" do

        it "raises an error" do
          expect {
            person.preferences.create!(name: "a")
          }.to raise_error(Mongoid::Errors::Validations)
        end
      end
    end
  end

  describe "#delete" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      Preference.create(name: "Testing")
    end

    let(:preference_two) do
      Preference.create(name: "Test")
    end

    before do
      person.preferences << [ preference_one, preference_two ]
    end

    context "when the document exists" do

      let!(:deleted) do
        person.preferences.delete(preference_one)
      end

      it "removes the document from the relation" do
        person.preferences.should eq([ preference_two ])
      end

      it "returns the document" do
        deleted.should eq(preference_one)
      end

      it "removes the document key from the foreign key" do
        person.preference_ids.should eq([ preference_two.id ])
      end

      it "removes the inverse reference" do
        deleted.reload.people.should be_empty
      end

      it "removes the base id from the inverse keys" do
        deleted.reload.person_ids.should be_empty
      end

      context "and person and preferences are reloaded" do

        before do
          person.reload
          preference_one.reload
          preference_two.reload
        end

        it "nullifies the deleted preference" do
          person.preferences.should eq([ preference_two ])
        end

        it "retains the ids for one preference" do
          person.preference_ids.should eq([ preference_two.id ])
        end
      end
    end

    context "when the document does not exist" do

      let!(:deleted) do
        person.preferences.delete(Preference.new)
      end

      it "returns nil" do
        deleted.should be_nil
      end

      it "does not modify the relation" do
        person.preferences.should eq([ preference_one, preference_two ])
      end

      it "does not modify the keys" do
        person.preference_ids.should eq([ preference_one.id, preference_two.id ])
      end
    end

    context "when :dependent => :nullify is set" do

      context "when :inverse_of is set" do

        let(:event) do
          Event.create
        end

        before do
          person.administrated_events << [ event ]
        end

        it "deletes the document" do
          event.delete.should be_true
        end
      end
    end

    context "when the relationships are self referencing" do

      let(:tag_one) do
        Tag.create(text: "one")
      end

      let(:tag_two) do
        Tag.create(text: "two")
      end

      before do
        tag_one.related << tag_two
      end

      context "when deleting without reloading" do

        let!(:deleted) do
          tag_one.related.delete(tag_two)
        end

        it "deletes the document from the relation" do
          tag_one.related.should be_empty
        end

        it "deletes the foreign key from the relation" do
          tag_one.related_ids.should be_empty
        end

        it "removes the reference from the inverse" do
          deleted.related.should be_empty
        end

        it "removes the foreign keys from the inverse" do
          deleted.related_ids.should be_empty
        end
      end

      context "when deleting with reloading" do

        context "when deleting from the front side" do

          let(:reloaded) do
            tag_one.reload
          end

          let!(:deleted) do
            reloaded.related.delete(tag_two)
          end

          it "deletes the document from the relation" do
            reloaded.related.should be_empty
          end

          it "deletes the foreign key from the relation" do
            reloaded.related_ids.should be_empty
          end

          it "removes the reference from the inverse" do
            deleted.related.should be_empty
          end

          it "removes the foreign keys from the inverse" do
            deleted.related_ids.should be_empty
          end
        end

        context "when deleting from the inverse side" do

          let(:reloaded) do
            tag_two.reload
          end

          let!(:deleted) do
            reloaded.related.delete(tag_one)
          end

          it "deletes the document from the relation" do
            reloaded.related.should be_empty
          end

          it "deletes the foreign key from the relation" do
            reloaded.related_ids.should be_empty
          end

          it "removes the foreign keys from the inverse" do
            deleted.related_ids.should be_empty
          end
        end
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      context "when the relation is not polymorphic" do

        context "when conditions are provided" do

          let(:person) do
            Person.create
          end

          let!(:preference_one) do
            person.preferences.create(name: "Testing")
          end

          let!(:preference_two) do
            person.preferences.create(name: "Test")
          end

          let!(:deleted) do
            person.preferences.send(
              method,
              { name: "Testing" }
            )
          end

          it "removes the correct preferences" do
            person.preferences.count.should eq(1)
          end

          it "deletes the documents from the database" do
            Preference.where(name: "Testing").count.should eq(0)
          end

          it "returns the number of documents deleted" do
            deleted.should eq(1)
          end

          it "removes the ids from the foreign key" do
            person.preference_ids.should eq([ preference_two.id ])
          end
        end

        context "when conditions are not provided" do

          let(:person) do
            Person.create.tap do |person|
              person.preferences.create(name: "Testing")
              person.preferences.create(name: "Test")
            end
          end

          let!(:deleted) do
            person.preferences.send(method)
          end

          it "removes the correct preferences" do
            person.preferences.count.should eq(0)
          end

          it "deletes the documents from the database" do
            Preference.count.should eq(0)
          end

          it "returns the number of documents deleted" do
            deleted.should eq(2)
          end
        end
      end
    end
  end

  describe ".eager_load" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when the relation is not polymorphic" do

      let!(:person) do
        Person.create
      end

      let!(:preference) do
        person.preferences.create(name: "testing")
      end

      let(:metadata) do
        Person.relations["preferences"]
      end

      let(:ids) do
        [ preference.id ]
      end

      let!(:eager) do
        described_class.eager_load(metadata, ids)
      end

      let(:map) do
        Mongoid::IdentityMap.get(Preference, ids)
      end

      it "puts the documents in the identity map" do
        map.should eq([ preference ])
      end
    end
  end

  describe ".embedded?" do

    it "returns false" do
      described_class.should_not be_embedded
    end
  end

  describe "#exists?" do

    let!(:person) do
      Person.create
    end

    context "when documents exist in the database" do

      before do
        person.preferences.create
      end

      it "returns true" do
        person.preferences.exists?.should be_true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.preferences.build
      end

      it "returns false" do
        person.preferences.exists?.should be_false
      end
    end
  end

  describe "#find" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:preference_one) do
        person.preferences.create(name: "Test")
      end

      let!(:preference_two) do
        person.preferences.create(name: "OMG I has relations")
      end

      let!(:unrelated_pref) do
        Preference.create(name: "orphan annie")
      end

      let!(:unrelated_pref_two) do
        Preference.create(name: "orphan two")
      end

      context "when providing an id" do

        context "when the id matches" do

          let(:preference) do
            person.preferences.find(preference_one.id)
          end

          it "returns the matching document" do
            preference.should eq(preference_one)
          end
        end

        context "when the id matches an unreferenced document" do

          let(:preference) do
            person.preferences.find(unrelated_pref.id)
          end

          it "raises an error" do
            expect {
              preference
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when the id does not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                person.preferences.find(BSON::ObjectId.new)
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:preference) do
              person.preferences.find(BSON::ObjectId.new)
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns nil" do
              preference.should be_nil
            end
          end
        end
      end

      context "when providing an array of ids" do

        context "when the ids match" do

          let(:preferences) do
            person.preferences.find([ preference_one.id, preference_two.id ])
          end

          it "returns the matching documents" do
            preferences.should eq([ preference_one, preference_two ])
          end
        end

        context "when the ids matche unreferenced documents" do

          let(:preferences) do
            person.preferences.find(
              [ unrelated_pref.id, unrelated_pref_two.id ]
            )
          end

          it "raises an error" do
            expect {
              preferences
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when the ids do not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                person.preferences.find([ BSON::ObjectId.new ])
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:preferences) do
              person.preferences.find([ BSON::ObjectId.new ])
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns an empty array" do
              preferences.should be_empty
            end
          end
        end
      end
    end
  end

  describe "#find_or_create_by" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:preference) do
        person.preferences.create(name: "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.preferences.find_or_create_by(name: "Testing")
        end

        it "returns the document" do
          found.should eq(preference)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.preferences.find_or_create_by(name: "Test")
        end

        it "sets the new document attributes" do
          found.name.should eq("Test")
        end

        it "returns a newly persisted document" do
          found.should be_persisted
        end
      end
    end
  end

  describe "#find_or_initialize_by" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:preference) do
        person.preferences.create(name: "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.preferences.find_or_initialize_by(name: "Testing")
        end

        it "returns the document" do
          found.should eq(preference)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.preferences.find_or_initialize_by(name: "Test")
        end

        it "sets the new document attributes" do
          found.name.should eq("Test")
        end

        it "returns a non persisted document" do
          found.should_not be_persisted
        end
      end
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _ids" do
      described_class.foreign_key_suffix.should eq("_ids")
    end
  end

  describe ".macro" do

    it "returns has_and_belongs_to_many" do
      described_class.macro.should eq(:has_and_belongs_to_many)
    end
  end

  describe "#max" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      Preference.create(ranking: 5)
    end

    let(:preference_two) do
      Preference.create(ranking: 10)
    end

    before do
      person.preferences.push(preference_one, preference_two)
    end

    let(:max) do
      person.preferences.max do |a,b|
        a.ranking <=> b.ranking
      end
    end

    it "returns the document with the max value of the supplied field" do
      max.should eq(preference_two)
    end
  end

  describe "#max_by" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      Preference.create(ranking: 5)
    end

    let(:preference_two) do
      Preference.create(ranking: 10)
    end

    before do
      person.preferences.push(preference_one, preference_two)
    end

    let(:max) do
      person.preferences.max_by(&:ranking)
    end

    it "returns the document with the max value of the supplied field" do
      max.should eq(preference_two)
    end
  end

  describe "#method_missing" do

    let!(:person) do
      Person.create
    end

    let!(:preference_one) do
      person.preferences.create(name: "First", value: "Posting")
    end

    let!(:preference_two) do
      person.preferences.create(name: "Second", value: "Testing")
    end

    let!(:unrelated) do
      Preference.create(name: "Third")
    end

    context "when providing a single criteria" do

      let(:preferences) do
        person.preferences.where(name: "First")
      end

      it "applies the criteria to the documents" do
        preferences.should eq([ preference_one ])
      end
    end

    context "when providing a criteria on id" do

      let(:preferences) do
        person.preferences.where(_id: unrelated.id)
      end

      it "does not return unrelated documents" do
        preferences.should be_empty
      end
    end

    context "when providing a criteria class method" do

      let(:preferences) do
        person.preferences.posting
      end

      it "applies the criteria to the documents" do
        preferences.should eq([ preference_one ])
      end
    end

    context "when chaining criteria" do

      let(:preferences) do
        person.preferences.posting.where(:name.in => [ "First" ])
      end

      it "applies the criteria to the documents" do
        preferences.should eq([ preference_one ])
      end
    end

    context "when delegating methods" do

      describe "#distinct" do

        it "returns the distinct values for the fields" do
          person.preferences.distinct(:name).should =~
            [ "First",  "Second"]
        end

        context "when the inverse relation is not defined" do

          let!(:house) do
            person.houses.create(name: "Wayne Manor")
          end

          it "returns the distinct values for the fields" do
            person.houses.distinct(:name).should eq([ house.name ])
          end
        end
      end
    end
  end

  describe "#min" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      Preference.create(ranking: 5)
    end

    let(:preference_two) do
      Preference.create(ranking: 10)
    end

    before do
      person.preferences.push(preference_one, preference_two)
    end

    let(:min) do
      person.preferences.min do |a, b|
        a.ranking <=> b.ranking
      end
    end

    it "returns the min value of the supplied field" do
      min.should eq(preference_one)
    end
  end

  describe "#min_by" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      Preference.create(ranking: 5)
    end

    let(:preference_two) do
      Preference.create(ranking: 10)
    end

    before do
      person.preferences.push(preference_one, preference_two)
    end

    let(:min) do
      person.preferences.min_by(&:ranking)
    end

    it "returns the min value of the supplied field" do
      min.should eq(preference_one)
    end
  end

  describe "#nil?" do

    it "returns false" do
      Person.new.preferences.should_not be_nil
    end
  end

  describe "#nullify_all" do

    let(:person) do
      Person.create
    end

    let!(:preference_one) do
      person.preferences.create(name: "One")
    end

    let!(:preference_two) do
      person.preferences.create(name: "Two")
    end

    before do
      person.preferences.nullify_all
    end

    it "removes the foreign key from the base document" do
      [ preference_one, preference_two ].each do |preference|
        person.preference_ids.should_not include(preference.id)
      end
    end

    it "removes the foreign key from the target documents" do
      [ preference_one, preference_two ].each do |preference|
        preference.person_ids.should_not include(person.id)
      end
    end

    it "removes the reference from the base document" do
      [ preference_one, preference_two ].each do |preference|
        person.preferences.should_not include(preference)
      end
    end

    it "removes the reference from the target documents" do
      [ preference_one, preference_two ].each do |preference|
        preference.people.should_not include(person)
      end
    end

    it "saves the documents" do
      preference_one.reload.people.should_not include(person)
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:preferences) do
      person.preferences
    end

    Array.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end

    Mongoid::Relations::Referenced::Many.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end

    Preference.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns true" do
      described_class.stores_foreign_key?.should be_true
    end
  end

  describe "#scoped" do

    let(:person) do
      Person.new
    end

    let(:scoped) do
      person.preferences.scoped
    end

    it "returns the relation criteria" do
      scoped.should be_a(Mongoid::Criteria)
    end

    it "returns with an empty selector" do
      scoped.selector.should eq({ "$and" => [{ "_id" => { "$in" => [] }}]})
    end
  end

  [ :size, :length ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create
      end

      context "when documents have been persisted" do

        let!(:preference) do
          person.preferences.create(name: "Testing")
        end

        it "returns the number of documents" do
          person.preferences.send(method).should eq(1)
        end
      end

      context "when documents have not been persisted" do

        before do
          person.preferences.build(name: "Test")
          person.preferences.create(name: "Test 2")
        end

        it "returns the total number of documents" do
          person.preferences.send(method).should eq(2)
        end
      end
    end
  end

  describe "#unscoped" do

    context "when the relation has no default scope" do

      let!(:person) do
        Person.create
      end

      let!(:preference_one) do
        person.preferences.create(name: "first")
      end

      let!(:preference_two) do
        Preference.create(name: "second")
      end

      let(:unscoped) do
        person.preferences.unscoped
      end

      it "returns only the associated documents" do
        unscoped.should eq([ preference_one ])
      end
    end

    context "when the relation has a default scope" do

      let!(:person) do
        Person.create
      end

      let!(:house_one) do
        person.houses.create(name: "first")
      end

      let!(:house_two) do
        House.create(name: "second")
      end

      let(:unscoped) do
        person.houses.unscoped
      end

      it "only returns associated documents" do
        unscoped.should eq([ house_one ])
      end

      it "removes the default scoping options" do
        unscoped.options.should eq({})
      end
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should eq(
        [ :autosave, :dependent, :foreign_key, :index, :order ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should be_true
    end
  end

  context "when setting the ids directly after the documents" do

    let!(:person) do
      Person.create!(title: "The Boss")
    end

    let!(:girlfriend_house) do
      House.create!(name: "Girlfriend")
    end

    let!(:wife_house) do
      House.create!(name: "Wife")
    end

    let!(:exwife_house) do
      House.create!(name: "Ex-Wife")
    end

    before do
      person.update_attributes(
        houses: [ wife_house, exwife_house, girlfriend_house ]
      )
      person.update_attributes(house_ids: [ girlfriend_house.id ])
    end

    context "when reloading" do

      it "properly sets the references" do
        person.houses(true).should eq([ girlfriend_house ])
      end
    end
  end

  context "when setting both sides in a single call" do

    context "when the documents are new" do

      let(:user) do
        User.new(name: "testing")
      end

      let(:business) do
        Business.new(name: "serious", owners: [ user ])
      end

      before do
        user.businesses = [ business ]
      end

      it "sets the businesses" do
        user.businesses.should eq([ business ])
      end

      it "sets the inverse users" do
        user.businesses.first.owners.first.should eq(user)
      end

      it "sets the inverse businesses" do
        business.owners.should eq([ user ])
      end
    end

    context "when one side is persisted" do

      let!(:user) do
        User.new(name: "testing")
      end

      let!(:business) do
        Business.create(name: "serious", owners: [ user ])
      end

      before do
        user.businesses = [ business ]
      end

      it "sets the businesses" do
        user.businesses.should eq([ business ])
      end

      it "sets the inverse users" do
        user.businesses.first.owners.first.should eq(user)
      end

      it "sets the inverse businesses" do
        business.owners.should eq([ user ])
      end

      context "when reloading" do

        before do
          user.reload
          business.reload
        end

        it "persists the businesses" do
          user.businesses.should eq([ business ])
        end

        it "persists the inverse users" do
          user.businesses.first.owners.first.should eq(user)
        end

        it "persists the inverse businesses" do
          business.owners.should eq([ user ])
        end
      end
    end

    context "when the documents are persisted" do

      let(:user) do
        User.create(name: "tst")
      end

      let(:business) do
        Business.create(name: "srs", owners: [ user ])
      end

      before do
        user.businesses = [ business ]
      end

      it "sets the businesses" do
        user.businesses.should eq([ business ])
      end

      it "sets the inverse users" do
        user.businesses.first.owners.first.should eq(user)
      end

      it "sets the inverse businesses" do
        business.owners.should eq([ user ])
      end

      context "when reloading" do

        before do
          user.reload
          business.reload
        end

        it "persists the businesses" do
          user.businesses.should eq([ business ])
        end

        it "persists the inverse users" do
          user.businesses.first.owners.first.should eq(user)
        end

        it "persists the inverse businesses" do
          business.owners.should eq([ user ])
        end
      end
    end
  end

  context "when binding the relation multiple times" do

    let(:person) do
      Person.create
    end

    let(:preference) do
      person.preferences.create(name: "testing")
    end

    before do
      2.times do
        person.preferences.each do |preference|
          preference.person_ids.should eq([ person.id ])
        end
      end
    end

    it "does not duplicate foreign keys" do
      person.preference_ids.should eq([ preference.id ])
    end
  end

  context "when the association has order criteria" do

    let(:person) do
      Person.create
    end

    let(:preference_one) do
      OrderedPreference.create(name: 'preference-1', value: 10)
    end

    let(:preference_two) do
      OrderedPreference.create(name: 'preference-2', value: 20)
    end

    let(:preference_three) do
      OrderedPreference.create(name: 'preference-3', value: 20)
    end

    before do
      person.ordered_preferences.nullify_all
      person.ordered_preferences.push(preference_one, preference_two, preference_three)
    end

    it "orders the documents" do
      person.ordered_preferences(true).should eq(
        [preference_two, preference_three, preference_one]
      )
    end

    it "chains default criteria with additional" do
      person.ordered_preferences.order_by(:name.desc).to_a.should eq(
        [preference_three, preference_two, preference_one]
      )
    end
  end

  context "when the parent is not a new record and freshly loaded" do

    let(:person) do
      Person.create
    end

    let(:preference) do
      Preference.new
    end

    before do
      person.preferences = [ preference ]
      person.save
      person.reload
      person.preferences = nil
    end

    it "sets the relation to an empty array" do
      person.preferences.should be_empty
    end

    it "removes the foreign key values" do
      person.preference_ids.should be_empty
    end

    it "does not delete the target from the database" do
      expect {
        preference.reload
      }.not_to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  context "when reloading the relation" do

    let!(:person) do
      Person.create
    end

    let!(:preference_one) do
      Preference.create(name: "one")
    end

    let!(:preference_two) do
      Preference.create(name: "two")
    end

    before do
      person.preferences << preference_one
    end

    context "when the relation references the same documents" do

      before do
        Preference.collection.find({ _id: preference_one.id }).
          update({ "$set" => { name: "reloaded" }})
      end

      let(:reloaded) do
        person.preferences(true)
      end

      it "reloads the document from the database" do
        reloaded.first.name.should eq("reloaded")
      end
    end

    context "when the relation references different documents" do

      before do
        person.preferences << preference_two
      end

      let(:reloaded) do
        person.preferences(true)
      end

      it "reloads the new document from the database" do
        reloaded.should eq([ preference_one, preference_two ])
      end
    end
  end

  context "when adding to a relation via a field setter" do

    context "when the document is new" do

      let!(:person) do
        Person.create(preference_names: "one, two")
      end

      let(:preference_one) do
        person.reload.preferences.first
      end

      let(:preference_two) do
        person.reload.preferences.last
      end

      it "persists the first preference" do
        preference_one.should_not be_nil
      end

      it "sets the first inverse" do
        preference_one.people.should eq([ person ])
      end

      it "persists the second preference" do
        preference_two.should_not be_nil
      end

      it "sets the second inverse keys" do
        preference_two.people.should eq([ person ])
      end
    end
  end

  context "when changing the order of existing ids" do

    let(:person) do
      Person.new
    end

    let(:preference_one) do
      Preference.create(name: "one")
    end

    let(:preference_two) do
      Preference.create(name: "two")
    end

    before do
      person.preference_ids = [ preference_one.id, preference_two.id ]
      person.save
    end

    context "and the order is changed" do

      before do
        person.preference_ids = [ preference_two.id, preference_one.id ]
        person.save
      end

      let(:reloaded) do
        Person.find(person.id)
      end

      it "persists the change in id order" do
        reloaded.preference_ids.should eq(
          [ preference_two.id, preference_one.id ]
        )
      end
    end

    context "and the order is changed and an element is added" do

      let(:preference_three) do
        Preference.create(name: "three")
      end

      before do
        person.preference_ids =
          [ preference_two.id, preference_one.id, preference_three.id ]
        person.save
      end

      let(:reloaded) do
        Person.find(person.id)
      end

      it "also persists the change in id order" do
        reloaded.preference_ids.should eq(
          [ preference_two.id, preference_one.id, preference_three.id ]
        )
      end
    end

    context "and the order is changed and an element is removed" do

      let(:preference_three) do
        Preference.create(name: "three")
      end

      before do
        person.preference_ids =
          [ preference_one.id, preference_two.id, preference_three.id ]
        person.save
        person.preference_ids =
          [ preference_three.id, preference_two.id ]
        person.save
      end

      let(:reloaded) do
        Person.find(person.id)
      end

      it "also persists the change in id order" do
        reloaded.preference_ids.should eq(
          [ preference_three.id, preference_two.id ]
        )
      end
    end
  end

  context "when adding a document" do

    let(:person) do
      Person.new
    end

    let(:preference_one) do
      Preference.new
    end

    let(:first_add) do
      person.preferences.push(preference_one)
    end

    context "when chaining a second add" do

      let(:preference_two) do
        Preference.new
      end

      let(:result) do
        first_add.push(preference_two)
      end

      it "adds both documents" do
        result.should eq([ preference_one, preference_two ])
      end
    end
  end
end
