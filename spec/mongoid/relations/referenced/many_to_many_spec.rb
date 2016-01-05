require "spec_helper"

describe Mongoid::Relations::Referenced::ManyToMany do

  before(:all) do
    Mongoid.raise_not_found_error = true
    Person.autosave(Person.relations["preferences"].merge!(autosave: true))
    Person.synced(Person.relations["preferences"])
  end

  after(:all) do
    Person.reset_callbacks(:save)
    Person.reset_callbacks(:destroy)
  end

  [ :<<, :push ].each do |method|

    describe "##{method}" do

      context "when the inverse_of is nil" do

        let!(:article) do
          Article.create
        end

        context "when the child document is new" do

          let(:preference) do
            Preference.new
          end

          before do
            article.preferences.send(method, preference)
          end

          it "persists the child document" do
            expect(preference).to be_persisted
          end
        end

        context "when the child document is not new" do

          let(:preference) do
            Preference.create
          end

          it "does not persist the child document" do
            expect(preference).to receive(:save).never
            article.preferences.send(method, preference)
          end
        end
      end

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
          expect(result).to eq([ preference ])
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
          expect(result).to eq([ preference ])
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
            expect(person.houses).to eq([ house ])
          end

          it "sets the foreign key on the relation" do
            expect(person.house_ids).to eq([ house.id ])
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
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "saves the target" do
            expect(preference).to be_persisted
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
          end

          it "persists the link" do
            expect(person.reload.preferences).to eq([ preference ])
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
              expect(person.preferences).to eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              expect(person.preference_ids).to eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              expect(preference.person_ids).to eq([ person.id ])
            end

            it "does not save the target" do
              expect(preference).to be_new_record
            end

            it "adds the correct number of documents" do
              expect(person.preferences.size).to eq(1)
            end

            context "when appending a second time" do

              before do
                person.preferences.send(method, preference)
              end

              it "does not allow the document to be added again" do
                expect(person.preferences).to eq([ preference ])
              end

              it "does not allow duplicate ids" do
                expect(person.preference_ids).to eq([ preference.id ])
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
              expect(person.preferences).to eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              expect(person.preference_ids).to eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              expect(preference.person_ids).to eq([ person.id ])
            end

            it "saves the target" do
              expect(preference).to be_persisted
            end

            it "adds the correct number of documents" do
              expect(person.preferences.size).to eq(1)
            end

            it "persists the link" do
              expect(person.reload.preferences).to eq([ preference ])
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
              expect(person.preferences).to eq([ preference ])
            end

            it "sets the foreign key on the relation" do
              expect(person.preference_ids).to eq([ preference.id ])
            end

            it "sets the foreign key on the inverse relation" do
              expect(preference.reload.person_ids).to eq([ person.id ])
            end

            it "adds the correct number of documents" do
              expect(person.preferences.size).to eq(1)
            end

            it "persists the link" do
              expect(person.reload.preferences).to eq([ preference ])
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
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "sets the base on the inverse relation" do
            expect(preference.people).to eq([ person ])
          end

          it "sets the same instance on the inverse relation" do
            expect(preference.people.first).to eql(person)
          end

          it "saves the target" do
            expect(preference).to_not be_new_record
          end

          it "adds the document to the target" do
            expect(person.preferences.count).to eq(1)
          end

          context "when documents already exist on the relation" do

            let(:preference_two) do
              Preference.new
            end

            before do
              person.preferences.send(method, preference_two)
            end

            it "adds the documents to the relation" do
              expect(person.preferences).to eq([ preference, preference_two ])
            end

            it "sets the foreign key on the relation" do
              expect(person.preference_ids).to eq([ preference.id, preference_two.id ])
            end

            it "sets the foreign key on the inverse relation" do
              expect(preference_two.person_ids).to eq([ person.id ])
            end

            it "sets the base on the inverse relation" do
              expect(preference_two.people).to eq([ person ])
            end

            it "sets the same instance on the inverse relation" do
              expect(preference_two.people.first).to eql(person)
            end

            it "saves the target" do
              expect(preference).to_not be_new_record
            end

            it "adds the document to the target" do
              expect(person.preferences.count).to eq(2)
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
            expect(person.administrated_events).to eq([ event ])
          end

          it "sets the inverse side of the relation" do
            expect(event.administrators(true)).to eq([ person ])
          end

          context "when reloading" do

            it "sets the front side of the relation" do
              expect(person.reload.administrated_events).to eq([ event ])
            end

            it "sets the inverse side of the relation" do
              expect(event.reload.administrators).to eq([ person ])
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
              expect(loaded_person.administrated_events).to eq([ event ])
            end

            it "sets the inverse side of the relation" do
              expect(loaded_event.administrators).to eq([ person ])
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
            expect(Artwork.count).to eq(1)
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
            expect(tag_one.related).to eq([ tag_two ])
          end

          it "sets the inverse side of the relation" do
            expect(tag_two.related(true)).to eq([ tag_one ])
          end

          context "when reloading" do

            it "sets the front side of the relation" do
              expect(tag_one.reload.related).to eq([ tag_two ])
            end

            it "sets the inverse side of the relation" do
              expect(tag_two.reload.related).to eq([ tag_one ])
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
              expect(loaded_tag_one.related).to eq([ tag_two ])
            end

            it "sets the inverse side of the relation" do
              expect(loaded_tag_two.related).to eq([ tag_one ])
            end
          end
        end
      end

      context "when association has callbacks" do

        let(:post) do
          Post.new
        end

        let(:tag) do
          Tag.new
        end

        context "when the callback is a before_add" do

          it "executes the callback" do
            post.tags.send(method, tag)
            expect(post.before_add_called).to be true
          end

          context "when errors are raised" do

            before do
              expect(post).to receive(:before_add_tag).and_raise
            end

            it "does not add the document to the relation" do
              expect {
                post.tags.send(method, tag)
              }.to raise_error
              expect(post.tags).to be_empty
            end
          end
        end

        context "when the callback is an after_add" do

          it "executes the callback" do
            post.tags.send(method, tag)
            expect(post.after_add_called).to be true
          end

          context "when errors are raised" do

            before do
              expect(post).to receive(:after_add_tag).and_raise
            end

            it "adds the document to the relation" do
              expect {
                post.tags.send(method, tag)
              }.to raise_error
              expect(post.tags).to eq([ tag ])
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
          expect(person.preferences).to eq([ preference ])
        end

        it "does not create duplicate keys" do
          expect(person.preference_ids).to eq([ preference.id ])
        end
      end

      context "when the document is persisted" do

        before do
          person.save
        end

        it "does not add the duplicates" do
          expect(person.preferences).to eq([ preference ])
        end

        it "does not create duplicate keys" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "does not add duplicates on the inverse" do
          expect(preference.people).to eq([ person ])
        end

        it "does not add duplicate inverse keys" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        context "when reloading document from db" do

          let(:from_db) { Preference.last }

          it "does not create duplicate keys" do
            person.preferences = [ from_db ]
            expect(from_db.person_ids).to eq([ person.id ])
          end
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
          expect(person.preferences).to eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        it "does not save the target" do
          expect(preference).to be_new_record
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
          expect(person.preferences).to eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        context "and the parent is persisted" do

          before do
            person.save!
            preference.reload
          end

          it "maintains the relation" do
            expect(person.preferences).to eq([ preference ])
          end

          it "maintains the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "maintains the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "maintains the base on the inverse relation" do
            expect(preference.people.first).to eq(person)
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
          expect(person.preferences).to eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        it "sets the base on the inverse relation" do
          expect(preference.people.first).to eq(person)
        end

        it "saves the target" do
          expect(preference).to be_persisted
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
            expect(person.preferences).to eq([ another_preference ])
          end

          it "saves the target" do
            expect(another_preference).to be_persisted
          end

          it "does not leave foreign keys of the previous relation" do
            expect(person.preference_ids).to eq([ another_preference.id ])
          end

          it "clears its own key on the foreign relation" do
            expect(preference.person_ids).to be_empty
          end

          context "and then overwriting it again with the same value" do

            before do
              person.preferences = [ another_preference ]
            end

            it "persists the relation between another_preference and person" do
              expect(another_preference.reload.people).to eq([ person ])
            end

          end

          context "and person reloaded instead of saved" do

            before do
              person.reload
              another_preference.reload
            end

            it "persists the relation between person and another_preference" do
              expect(person.preferences).to eq([ another_preference ])
            end

            it "persists the relation between another_prefrence and person" do
              expect(another_preference.people).to eq([ person ])
            end

            it "no longer has any relation between preference and person" do
              expect(preference.people).to be_empty
            end
          end

          context "and person is saved" do

            before do
              person.save
              person.reload
              another_preference.reload
            end

            it "persists the relation between person and another_preference" do
              expect(person.preferences).to eq([ another_preference ])
            end

            it "persists the relation between another_prefrence and person" do
              expect(another_preference.people).to eq([ person ])
            end

            it "no longer has any relation between preference and person" do
              expect(preference.people).to be_empty
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
            expect(person.houses).to be_empty
          end

          it "clears the foreign keys" do
            expect(person.house_ids).to be_empty
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
            expect(person.preferences).to be_empty
          end

          it "removed the inverse relation" do
            expect(preference.people).to be_empty
          end

          it "removes the foreign key values" do
            expect(person.preference_ids).to be_empty
          end

          it "removes the inverse foreign key values" do
            expect(preference.person_ids).to be_empty
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
              expect(person.preferences).to be_empty
            end

            it "removed the inverse relation" do
              expect(preference.people).to be_empty
            end

            it "removes the foreign key values" do
              expect(person.preference_ids).to be_empty
            end

            it "removes the inverse foreign key values" do
              expect(preference.person_ids).to be_empty
            end

            it "does not delete the target from the database" do
              expect(preference).to_not be_destroyed
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
              expect(from_db.preferences).to be_empty
            end

            it "removes the foreign key values" do
              expect(from_db.preference_ids).to be_empty
            end
          end
        end
      end
    end
  end

  [ :build, :new ].each do |method|

    describe "##{method}" do

      context "when the relation is not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          let!(:preference) do
            person.preferences.send(method, name: "settings")
          end

          it "adds the document to the relation" do
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the inverse foreign key on the relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "sets the attributes" do
            expect(preference.name).to eq("settings")
          end

          it "does not save the target" do
            expect(preference).to be_new_record
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
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
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the inverse foreign key on the relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "sets the base on the inverse relation" do
            expect(preference.people).to eq([ person ])
          end

          it "sets the attributes" do
            expect(preference.name).to eq("settings")
          end

          it "does not save the target" do
            expect(preference).to be_new_record
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
          end

          context "when saving the target" do

            before do
              preference.save
            end

            it "persists the parent keys" do
              expect(person.reload.preference_ids).to eq([ preference.id ])
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
      double
    end

    let(:metadata) do
      double(extension?: false)
    end

    it "returns the embedded in builder" do
      expect(
        described_class.builder(nil, metadata, document)
      ).to be_a_kind_of(builder_klass)
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
            expect(person.preferences).to be_empty
          end

          it "removes the parent from the inverse relation" do
            expect(preference.people).to_not include(person)
          end

          it "removes the foreign keys" do
            expect(person.preference_ids).to be_empty
          end

          it "removes the parent key from the inverse" do
            expect(preference.person_ids).to_not include(person.id)
          end

          it "does not delete the documents" do
            expect(preference).to_not be_destroyed
          end

          it "persists the nullification" do
            expect(person.reload.preferences).to be_empty
          end

          it "returns the relation" do
            expect(relation).to be_empty
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
            expect(person.preferences).to be_empty
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
          expect(person.preferences).to be_empty
        end
      end
    end

    context "when the association has callbacks" do

      let(:post) do
        Post.new
      end

      let(:tag) do
        Tag.new
      end

      before do
        post.tags << tag
      end

      context "when the callback is a before_remove" do

        context "when no errors are raised" do

          before do
            post.tags.clear
          end

          it "executes the callback" do
            expect(post.before_remove_called).to be true
          end

          it "removes the document from the relation" do
            expect(post.tags).to be_empty
          end
        end

        context "when errors are raised" do

          before do
            expect(post).to receive(:before_remove_tag).and_raise
          end

          it "does not remove the document from the relation" do
            expect {
              post.tags.clear
            }.to raise_error
            expect(post.tags).to eq([ tag ])
          end
        end
      end

      context "when the callback is an after_remove" do

        context "when no errors are raised" do

          before do
            post.tags.clear
          end

          it "executes the callback" do
            expect(post.after_remove_called).to be true
          end

          it "removes the document from the relation" do
            expect(post.tags).to be_empty
          end
        end

        context "when errors are raised" do

          before do
            expect(post).to receive(:after_remove_tag).and_raise
          end

          it "removes the document from the relation" do
            expect {
              post.tags.clear
            }.to raise_error
            expect(post.tags).to be_empty
          end
        end
      end
    end
  end

  describe "#concat" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let!(:preference) do
        Preference.new
      end

      let(:result) do
        person.preferences.concat([ preference ])
      end

      it "returns an array of loaded documents" do
        expect(result).to eq([ preference ])
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
        person.preferences.concat([ preference ])
      end

      it "returns an array of loaded documents" do
        expect(result).to eq([ preference ])
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
          person.houses.concat([ house ])
        end

        it "appends the document to the relation" do
          expect(person.houses).to eq([ house ])
        end

        it "sets the foreign key on the relation" do
          expect(person.house_ids).to eq([ house.id ])
        end
      end

      context "when appending in a parent create block" do

        let!(:preference) do
          Preference.create(name: "testing")
        end

        let!(:person) do
          Person.create do |doc|
            doc.preferences.concat([ preference ])
          end
        end

        it "adds the documents to the relation" do
          expect(person.preferences).to eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        it "saves the target" do
          expect(preference).to be_persisted
        end

        it "adds the correct number of documents" do
          expect(person.preferences.size).to eq(1)
        end

        it "persists the link" do
          expect(person.reload.preferences).to eq([ preference ])
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
            person.preferences.concat([ preference ])
          end

          it "adds the documents to the relation" do
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "does not save the target" do
            expect(preference).to be_new_record
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
          end

          context "when appending a second time" do

            before do
              person.preferences.concat([ preference ])
            end

            it "does not allow the document to be added again" do
              expect(person.preferences).to eq([ preference ])
            end

            it "does not allow duplicate ids" do
              expect(person.preference_ids).to eq([ preference.id ])
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
            person.preferences.concat([ preference ])
            person.save
          end

          it "adds the documents to the relation" do
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "saves the target" do
            expect(preference).to be_persisted
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
          end

          it "persists the link" do
            expect(person.reload.preferences).to eq([ preference ])
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
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.reload.person_ids).to eq([ person.id ])
          end

          it "adds the correct number of documents" do
            expect(person.preferences.size).to eq(1)
          end

          it "persists the link" do
            expect(person.reload.preferences).to eq([ preference ])
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
          person.preferences.concat([ preference ])
        end

        it "adds the documents to the relation" do
          expect(person.preferences).to eq([ preference ])
        end

        it "sets the foreign key on the relation" do
          expect(person.preference_ids).to eq([ preference.id ])
        end

        it "sets the foreign key on the inverse relation" do
          expect(preference.person_ids).to eq([ person.id ])
        end

        it "sets the base on the inverse relation" do
          expect(preference.people).to eq([ person ])
        end

        it "sets the same instance on the inverse relation" do
          expect(preference.people.first).to eql(person)
        end

        it "saves the target" do
          expect(preference).to_not be_new_record
        end

        it "adds the document to the target" do
          expect(person.preferences.count).to eq(1)
        end

        context "when documents already exist on the relation" do

          let(:preference_two) do
            Preference.new
          end

          before do
            person.preferences.concat([ preference_two ])
          end

          it "adds the documents to the relation" do
            expect(person.preferences).to eq([ preference, preference_two ])
          end

          it "sets the foreign key on the relation" do
            expect(person.preference_ids).to eq([ preference.id, preference_two.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference_two.person_ids).to eq([ person.id ])
          end

          it "sets the base on the inverse relation" do
            expect(preference_two.people).to eq([ person ])
          end

          it "sets the same instance on the inverse relation" do
            expect(preference_two.people.first).to eql(person)
          end

          it "saves the target" do
            expect(preference).to_not be_new_record
          end

          it "adds the document to the target" do
            expect(person.preferences.count).to eq(2)
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
          person.administrated_events.concat([ event ])
        end

        it "sets the front side of the relation" do
          expect(person.administrated_events).to eq([ event ])
        end

        it "sets the inverse side of the relation" do
          expect(event.administrators(true)).to eq([ person ])
        end

        context "when reloading" do

          it "sets the front side of the relation" do
            expect(person.reload.administrated_events).to eq([ event ])
          end

          it "sets the inverse side of the relation" do
            expect(event.reload.administrators).to eq([ person ])
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
            expect(loaded_person.administrated_events).to eq([ event ])
          end

          it "sets the inverse side of the relation" do
            expect(loaded_event.administrators).to eq([ person ])
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
          artwork.exhibitors.concat([ exhibitor ])
        end

        it "creates a single artwork object" do
          expect(Artwork.count).to eq(1)
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
          tag_one.related.concat([ tag_two ])
        end

        it "sets the front side of the relation" do
          expect(tag_one.related).to eq([ tag_two ])
        end

        it "sets the inverse side of the relation" do
          expect(tag_two.related(true)).to eq([ tag_one ])
        end

        context "when reloading" do

          it "sets the front side of the relation" do
            expect(tag_one.reload.related).to eq([ tag_two ])
          end

          it "sets the inverse side of the relation" do
            expect(tag_two.reload.related).to eq([ tag_one ])
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
            expect(loaded_tag_one.related).to eq([ tag_two ])
          end

          it "sets the inverse side of the relation" do
            expect(loaded_tag_two.related).to eq([ tag_one ])
          end
        end
      end
    end
  end

  describe "#count" do

    let(:person) do
      Person.create
    end

    context "when nothing exists on the relation" do

      context "when the document is destroyed" do

        before do
          Meat.create!
        end

        let!(:sandwich) do
          Sandwich.create!
        end

        it "returns zero" do
          sandwich.destroy
          expect(sandwich.meats.count).to eq(0)
        end
      end
    end

    context "when documents have been persisted" do

      let!(:preference) do
        person.preferences.create(name: "setting")
      end

      it "returns the number of persisted documents" do
        expect(person.preferences.count).to eq(1)
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
        expect(person.preferences.count).to eq(2)
      end
    end

    context "when documents have not been persisted" do

      let!(:preference) do
        person.preferences.build(name: "settings")
      end

      it "returns 0" do
        expect(person.preferences.count).to eq(0)
      end
    end

    context "when new documents exist in the database" do

      context "when the documents are part of the relation" do

        before do
          Preference.create(person_ids: [ person.id ])
        end

        it "returns the count from the db" do
          expect(person.reload.preferences.count).to eq(1)
        end
      end

      context "when the documents are not part of the relation" do

        before do
          Preference.create
        end

        it "returns the count from the db" do
          expect(person.preferences.count).to eq(0)
        end
      end
    end

    context "when the inverse relation is not defined" do

      context "when documents have been persisted" do

        let!(:house) do
          person.houses.create(name: "Wayne Manor")
        end

        it "returns the number of persisted documents" do
          expect(person.houses.count).to eq(1)
        end
      end

      context "when documents have not been persisted" do

        let!(:house) do
          person.houses.build(name: "Ryugyong Hotel")
        end

        it "returns 0" do
          expect(person.preferences.count).to eq(0)
        end
      end
    end
  end

  [ :create, :create! ].each do |method|

    describe "##{method}" do

      context "when the relation is not polymorphic" do

        context "when using string keys" do

          let(:agent) do
            Agent.create(number: "007")
          end

          before do
            agent.accounts.create(name: "testing again")
          end

          it "does not convert the string key to an object id" do
            expect(agent.account_ids).to eq([ "testing-again" ])
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
            expect(person.preference_ids).to eq([ preference.id ])
          end

          it "sets the foreign key on the inverse relation" do
            expect(preference.person_ids).to eq([ person.id ])
          end

          it "adds the document" do
            expect(person.preferences).to eq([ preference ])
          end

          it "sets the base on the inverse relation" do
            expect(preference.people).to eq([ person ])
          end

          it "sets the attributes" do
            expect(preference.name).to eq("Testing")
          end

          it "saves the target" do
            expect(preference).to be_persisted
          end

          it "adds the document to the target" do
            expect(person.preferences.count).to eq(1)
          end

          it "does not duplicate documents" do
            expect(person.reload.preferences.count).to eq(1)
          end

          it "does not duplicate ids" do
            expect(person.reload.preference_ids.count).to eq(1)
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
        expect(person.preferences).to eq([ preference_two ])
      end

      it "returns the document" do
        expect(deleted).to eq(preference_one)
      end

      it "removes the document key from the foreign key" do
        expect(person.preference_ids).to eq([ preference_two.id ])
      end

      it "removes the inverse reference" do
        expect(deleted.reload.people).to be_empty
      end

      it "removes the base id from the inverse keys" do
        expect(deleted.reload.person_ids).to be_empty
      end

      context "and person and preferences are reloaded" do

        before do
          person.reload
          preference_one.reload
          preference_two.reload
        end

        it "nullifies the deleted preference" do
          expect(person.preferences).to eq([ preference_two ])
        end

        it "retains the ids for one preference" do
          expect(person.preference_ids).to eq([ preference_two.id ])
        end
      end
    end

    context "when the document does not exist" do

      let!(:deleted) do
        person.preferences.delete(Preference.new)
      end

      it "returns nil" do
        expect(deleted).to be_nil
      end

      it "does not modify the relation" do
        expect(person.preferences).to eq([ preference_one, preference_two ])
      end

      it "does not modify the keys" do
        expect(person.preference_ids).to eq([ preference_one.id, preference_two.id ])
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
          expect(event.delete).to be true
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
          expect(tag_one.related).to be_empty
        end

        it "deletes the foreign key from the relation" do
          expect(tag_one.related_ids).to be_empty
        end

        it "removes the reference from the inverse" do
          expect(deleted.related).to be_empty
        end

        it "removes the foreign keys from the inverse" do
          expect(deleted.related_ids).to be_empty
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
            expect(reloaded.related).to be_empty
          end

          it "deletes the foreign key from the relation" do
            expect(reloaded.related_ids).to be_empty
          end

          it "removes the reference from the inverse" do
            expect(deleted.related).to be_empty
          end

          it "removes the foreign keys from the inverse" do
            expect(deleted.related_ids).to be_empty
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
            expect(reloaded.related).to be_empty
          end

          it "deletes the foreign key from the relation" do
            expect(reloaded.related_ids).to be_empty
          end

          it "removes the foreign keys from the inverse" do
            expect(deleted.related_ids).to be_empty
          end
        end
      end
    end

    context "when the association has callbacks" do

      let(:post) do
        Post.new
      end

      let(:tag) do
        Tag.new
      end

      before do
        post.tags << tag
      end

      context "when the callback is a before_remove" do

        context "when there are no errors" do

          before do
            post.tags.delete tag
          end

          it "executes the callback" do
            expect(post.before_remove_called).to be true
          end

          it "removes the document from the relation" do
            expect(post.tags).to be_empty
          end
        end

        context "when errors are raised" do

          before do
            expect(post).to receive(:before_remove_tag).and_raise
          end

          it "does not remove the document from the relation" do
            expect {
              post.tags.delete tag
            }.to raise_error
            expect(post.tags).to eq([ tag ])
          end
        end
      end

      context "when the callback is an after_remove" do

        context "when no errors are raised" do

          before do
            post.tags.delete(tag)
          end

          it "executes the callback" do
            expect(post.after_remove_called).to be true
          end

          it "removes the document from the relation" do
            expect(post.tags).to be_empty
          end
        end

        context "when errors are raised" do

          before do
            expect(post).to receive(:after_remove_tag).and_raise
          end

          it "removes the document from the relation" do
            expect {
              post.tags.delete(tag)
            }.to raise_error
            expect(post.tags).to be_empty
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
            expect(person.preferences.count).to eq(1)
          end

          it "deletes the documents from the database" do
            expect(Preference.where(name: "Testing").count).to eq(0)
          end

          it "returns the number of documents deleted" do
            expect(deleted).to eq(1)
          end

          it "removes the ids from the foreign key" do
            expect(person.preference_ids).to eq([ preference_two.id ])
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
            expect(person.preferences.count).to eq(0)
          end

          it "deletes the documents from the database" do
            expect(Preference.count).to eq(0)
          end

          it "returns the number of documents deleted" do
            expect(deleted).to eq(2)
          end
        end
      end
    end
  end

  describe ".embedded?" do

    it "returns false" do
      expect(described_class).to_not be_embedded
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
        expect(person.preferences.exists?).to be true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.preferences.build
      end

      it "returns false" do
        expect(person.preferences.exists?).to be false
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
            expect(preference).to eq(preference_one)
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
              expect(preference).to be_nil
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
            expect(preferences).to eq([ preference_one, preference_two ])
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
              expect(preferences).to be_empty
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
          expect(found).to eq(preference)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.preferences.find_or_create_by(name: "Test")
        end

        it "sets the new document attributes" do
          expect(found.name).to eq("Test")
        end

        it "returns a newly persisted document" do
          expect(found).to be_persisted
        end
      end
    end
  end

  describe "#find_or_create_by!" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:preference) do
        person.preferences.create(name: "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.preferences.find_or_create_by!(name: "Testing")
        end

        it "returns the document" do
          expect(found).to eq(preference)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.preferences.find_or_create_by!(name: "Test")
        end

        it "sets the new document attributes" do
          expect(found.name).to eq("Test")
        end

        it "returns a newly persisted document" do
          expect(found).to be_persisted
        end

        context "when validation fails" do

          it "raises an error" do
            expect {
              person.preferences.find_or_create_by!(name: "A")
            }.to raise_error(Mongoid::Errors::Validations)
          end
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
          expect(found).to eq(preference)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.preferences.find_or_initialize_by(name: "Test")
        end

        it "sets the new document attributes" do
          expect(found.name).to eq("Test")
        end

        it "returns a non persisted document" do
          expect(found).to_not be_persisted
        end
      end
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _ids" do
      expect(described_class.foreign_key_suffix).to eq("_ids")
    end
  end

  describe ".macro" do

    it "returns has_and_belongs_to_many" do
      expect(described_class.macro).to eq(:has_and_belongs_to_many)
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
      expect(max).to eq(preference_two)
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
      expect(max).to eq(preference_two)
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
        expect(preferences).to eq([ preference_one ])
      end
    end

    context "when providing a criteria on id" do

      let(:preferences) do
        person.preferences.where(_id: unrelated.id)
      end

      it "does not return unrelated documents" do
        expect(preferences).to be_empty
      end
    end

    context "when providing a criteria class method" do

      let(:preferences) do
        person.preferences.posting
      end

      it "applies the criteria to the documents" do
        expect(preferences).to eq([ preference_one ])
      end
    end

    context "when chaining criteria" do

      let(:preferences) do
        person.preferences.posting.where(:name.in => [ "First" ])
      end

      it "applies the criteria to the documents" do
        expect(preferences).to eq([ preference_one ])
      end
    end

    context "when delegating methods" do

      describe "#distinct" do

        let(:values) do
          person.preferences.distinct(:name)
        end

        it "returns the distinct values for the fields" do
          expect(values).to include("First")
          expect(values).to include("Second")
        end

        context "when the inverse relation is not defined" do

          let!(:house) do
            person.houses.create(name: "Wayne Manor")
          end

          it "returns the distinct values for the fields" do
            expect(person.houses.distinct(:name)).to eq([ house.name ])
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
      expect(min).to eq(preference_one)
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
      expect(min).to eq(preference_one)
    end
  end

  describe "#nil?" do

    it "returns false" do
      expect(Person.new.preferences).to_not be_nil
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
        expect(person.preference_ids).to_not include(preference.id)
      end
    end

    it "removes the foreign key from the target documents" do
      [ preference_one, preference_two ].each do |preference|
        expect(preference.person_ids).to_not include(person.id)
      end
    end

    it "removes the reference from the base document" do
      [ preference_one, preference_two ].each do |preference|
        expect(person.preferences).to_not include(preference)
      end
    end

    it "removes the reference from the target documents" do
      [ preference_one, preference_two ].each do |preference|
        expect(preference.people).to_not include(person)
      end
    end

    it "saves the documents" do
      expect(preference_one.reload.people).to_not include(person)
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
          expect(preferences.respond_to?(method)).to be true
        end
      end
    end

    Mongoid::Relations::Referenced::Many.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(preferences.respond_to?(method)).to be true
        end
      end
    end

    Preference.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(preferences.respond_to?(method)).to be true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns true" do
      expect(described_class.stores_foreign_key?).to be true
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
      expect(scoped).to be_a(Mongoid::Criteria)
    end

    it "returns with an empty selector" do
      expect(scoped.selector).to eq({ "$and" => [{ "_id" => { "$in" => [] }}]})
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
          expect(person.preferences.send(method)).to eq(1)
        end
      end

      context "when documents have not been persisted" do

        before do
          person.preferences.build(name: "Test")
          person.preferences.create(name: "Test 2")
        end

        it "returns the total number of documents" do
          expect(person.preferences.send(method)).to eq(2)
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
        expect(unscoped).to eq([ preference_one ])
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
        expect(unscoped).to eq([ house_one ])
      end

      it "removes the default scoping options" do
        expect(unscoped.options).to eq({})
      end
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      expect(described_class.valid_options).to eq(
        [
          :after_add,
          :after_remove,
          :autosave,
          :before_add,
          :before_remove,
          :dependent,
          :foreign_key,
          :index,
          :order,
          :primary_key
        ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      expect(described_class.validation_default).to be true
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
        expect(person.houses(true)).to eq([ girlfriend_house ])
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
        expect(user.businesses).to eq([ business ])
      end

      it "sets the inverse users" do
        expect(user.businesses.first.owners.first).to eq(user)
      end

      it "sets the inverse businesses" do
        expect(business.owners).to eq([ user ])
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
        expect(user.businesses).to eq([ business ])
      end

      it "sets the inverse users" do
        expect(user.businesses.first.owners.first).to eq(user)
      end

      it "sets the inverse businesses" do
        expect(business.owners).to eq([ user ])
      end

      context "when reloading" do

        before do
          user.reload
          business.reload
        end

        it "persists the businesses" do
          expect(user.businesses).to eq([ business ])
        end

        it "persists the inverse users" do
          expect(user.businesses.first.owners.first).to eq(user)
        end

        it "persists the inverse businesses" do
          expect(business.owners).to eq([ user ])
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
        expect(user.businesses).to eq([ business ])
      end

      it "sets the inverse users" do
        expect(user.businesses.first.owners.first).to eq(user)
      end

      it "sets the inverse businesses" do
        expect(business.owners).to eq([ user ])
      end

      context "when reloading" do

        before do
          user.reload
          business.reload
        end

        it "persists the businesses" do
          expect(user.businesses).to eq([ business ])
        end

        it "persists the inverse users" do
          expect(user.businesses.first.owners.first).to eq(user)
        end

        it "persists the inverse businesses" do
          expect(business.owners).to eq([ user ])
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
          expect(preference.person_ids).to eq([ person.id ])
        end
      end
    end

    it "does not duplicate foreign keys" do
      expect(person.preference_ids).to eq([ preference.id ])
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
      expect(person.ordered_preferences(true)).to eq(
        [preference_two, preference_three, preference_one]
      )
    end

    it "chains default criteria with additional" do
      expect(person.ordered_preferences.order_by(:name.desc).to_a).to eq(
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
      expect(person.preferences).to be_empty
    end

    it "removes the foreign key values" do
      expect(person.preference_ids).to be_empty
    end

    it "does not delete the target from the database" do
      expect {
        preference.reload
      }.not_to raise_error
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
          update_one({ "$set" => { name: "reloaded" }})
      end

      let(:reloaded) do
        person.preferences(true)
      end

      it "reloads the document from the database" do
        expect(reloaded.first.name).to eq("reloaded")
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
        expect(reloaded).to eq([ preference_one, preference_two ])
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
        expect(preference_one).to_not be_nil
      end

      it "sets the first inverse" do
        expect(preference_one.people).to eq([ person ])
      end

      it "persists the second preference" do
        expect(preference_two).to_not be_nil
      end

      it "sets the second inverse keys" do
        expect(preference_two.people).to eq([ person ])
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
        expect(reloaded.preference_ids).to eq(
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
        expect(reloaded.preference_ids).to eq(
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
        expect(reloaded.preference_ids).to eq(
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
        expect(result).to eq([ preference_one, preference_two ])
      end
    end
  end

  context "when setting the relation via the foreign key" do

    context "when the relation exists" do

      let!(:person) do
        Person.create
      end

      let!(:pref_one) do
        person.preferences.create
      end

      let!(:pref_two) do
        Preference.create
      end

      before do
        person.preference_ids = [ pref_two.id ]
      end

      it "sets the new documents on the relation" do
        expect(person.preferences).to eq([ pref_two ])
      end
    end
  end

  context "when using a different primary key" do

    let(:dog) do
      Dog.create(name: 'Doggie')
    end

    let(:cat) do
      Cat.create(name: 'Kitty')
    end

    let(:fire_hydrant) do
      FireHydrant.create(location: '221B Baker Street')
    end

    context "when adding to a one-way many to many" do

      before do
        fire_hydrant.cats.push(cat)
      end

      it "adds the pk value to the fk set" do
        expect(fire_hydrant.cat_ids).to eq([cat.name])
      end
    end

    context "when adding to a two-way many to many" do

      before do
        fire_hydrant.dogs.push(dog)
      end

      it "adds the pk value to the fk set" do
        expect(fire_hydrant.dog_ids).to eq([dog.name])
      end

      it "adds the base pk value to the inverse fk set" do
        expect(dog.fire_hydrant_ids).to eq([fire_hydrant.location])
      end
    end

    context "when deleting from a two-way many to many" do

      before do
        dog.fire_hydrants.push(fire_hydrant)
        fire_hydrant.dogs.delete(dog)
      end

      it "removes the pk value from the fk set" do
        expect(fire_hydrant.dog_ids).to eq([])
      end

      it "removes the base pk value from the inverse fk set" do
        expect(dog.fire_hydrant_ids).to eq([])
      end
    end
  end

  context "HABTM" do
    before do
      class Project
        include Mongoid::Document

        field :n, type: String, as: :name

        has_and_belongs_to_many :distributors,
          foreign_key: :d_ids,
          inverse_of: 'p',
          inverse_class_name: 'Distributor'
      end

      class Distributor
        include Mongoid::Document

        field :n, type: String, as: :name

        has_and_belongs_to_many :projects,
          foreign_key: :p_ids,
          inverse_of: 'd',
          inverse_class_name: 'Project'
      end
    end

    it "should assign relation from both sides" do
      p1 = Project.create name: 'Foo'
      p2 = Project.create name: 'Bar'
      d1 = Distributor.create name: 'Rock'
      d2 = Distributor.create name: 'Soul'

      p1.distributors << d1
      expect(p1.d_ids).to match_array([d1.id])
      expect(d1.p_ids).to match_array([p1.id])
      d2.projects << p2
      expect(d2.p_ids).to match_array([p2.id])
      expect(p2.d_ids).to match_array([d2.id])
    end
  end
end
