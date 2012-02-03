require "spec_helper"

describe Mongoid::Dirty do

  describe "#attribute_change" do

    context "when the attribute has changed from the persisted value" do

      let(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns an array of the old value and new value" do
        person.send(:attribute_change, "title").should eq(
          [ "Grand Poobah", "Captain Obvious" ]
        )
      end

      it "allows access via (attribute)_change" do
        person.title_change.should eq(
          [ "Grand Poobah", "Captain Obvious" ]
        )
      end
    end

    context "when the attribute has changed from the default value" do

      let(:person) do
        Person.new(pets: true)
      end

      it "returns an array of nil and new value" do
        person.send(:attribute_change, "pets").should eq([ nil, true ])
      end

      it "allows access via (attribute)_change" do
        person.pets_change.should eq([ nil, true ])
      end
    end

    context "when the attribute changes multiple times" do

      let(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      before do
        person.title = "Captain Obvious"
        person.title = "Dark Helmet"
      end

      it "returns an array of the original value and new value" do
        person.send(:attribute_change, "title").should eq(
          [ "Grand Poobah", "Dark Helmet" ]
        )
      end

      it "allows access via (attribute)_change" do
        person.title_change.should eq(
          [ "Grand Poobah", "Dark Helmet" ]
        )
      end
    end

    context "when the attribute is modified in place" do

      context "when the attribute is an array" do

        let(:person) do
          Person.new(aliases: [ "Grand Poobah" ]).tap(&:move_changes)
        end

        before do
          person.aliases[0] = "Dark Helmet"
        end

        it "returns an array of the original value and new value" do
          person.send(:attribute_change, "aliases").should eq(
            [[ "Grand Poobah" ],  [ "Dark Helmet" ]]
          )
        end

        it "allows access via (attribute)_change" do
          person.aliases_change.should eq(
            [[ "Grand Poobah" ],  [ "Dark Helmet" ]]
          )
        end

        context "when the attribute changes multiple times" do

          before do
            person.aliases << "Colonel Sanders"
          end

          it "returns an array of the original value and new value" do
            person.send(:attribute_change, "aliases").should eq(
              [[ "Grand Poobah" ], [ "Dark Helmet", "Colonel Sanders" ]]
            )
          end
        end
      end

      context "when the attribute is a hash" do

        let(:person) do
          Person.new(map: { location: "Home" }).tap(&:move_changes)
        end

        before do
          person.map[:location] = "Work"
        end

        it "returns an array of the original value and new value" do
          person.send(:attribute_change, "map").should eq(
            [{ location: "Home" }, { location: "Work" }]
          )
        end

        it "allows access via (attribute)_change" do
          person.map_change.should eq(
            [{ location: "Home" }, { location: "Work" }]
          )
        end

        context "when the attribute changes multiple times" do

          before do
            person.map[:lat] = 20.0
          end

          it "returns an array of the original value and new value" do
            person.send(:attribute_change, "map").should eq(
              [{ location: "Home" }, { location: "Work", lat: 20.0 }]
            )
          end
        end
      end
    end

    context "when the attribute has not changed from the persisted value" do

      let(:person) do
        Person.new(title: nil)
      end

      it "returns nil" do
        person.send(:attribute_change, "title").should be_nil
      end
    end

    context "when the attribute has not changed from the default value" do

      context "when the attribute differs from the persisted value" do

        let(:person) do
          Person.new
        end

        it "returns the change" do
          person.send(:attribute_change, "pets").should eq([ nil, false ])
        end
      end

      context "when the attribute does not differ from the persisted value" do

        let(:person) do
          Person.instantiate("pets" => false)
        end

        it "returns nil" do
          person.send(:attribute_change, "pets").should be_nil
        end
      end
    end

    context "when the attribute has been set with the same value" do

      let(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      before do
        person.title = "Grand Poobah"
      end

      it "returns an empty array" do
        person.send(:attribute_change, "title").should be_nil
      end
    end

    context "when the attribute is removed" do

      let(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      before do
        person.remove_attribute(:title)
      end

      it "returns an empty array" do
        person.send(:attribute_change, "title").should eq(
          [ "Grand Poobah", nil ]
        )
      end
    end
  end

  describe "#attribute_changed?" do

    context "when the attribute has changed from the persisted value" do

      let(:person) do
        Person.new(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns true" do
        person.send(:attribute_changed?, "title").should be_true
      end

      it "allows access via (attribute)_changed?" do
        person.title_changed?.should be_true
      end
    end

    context "when the attribute has changed from the default value" do

      let(:person) do
        Person.new
      end

      before do
        person.pets = true
      end

      it "returns true" do
        person.send(:attribute_changed?, "pets").should be_true
      end

      it "allows access via (attribute)_changed?" do
        person.pets_changed?.should be_true
      end
    end

    context "when the attribute has not changed the persisted value" do

      let!(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      it "returns false" do
        person.send(:attribute_changed?, "title").should be_false
      end
    end

    context "when the attribute has not changed from the default value" do

      context "when the attribute is not enumerable" do

        context "when the attribute differs from the persisted value" do

          let!(:person) do
            Person.new
          end

          it "returns true" do
            person.send(:attribute_changed?, "pets").should be_true
          end
        end

        context "when the attribute does not differ from the persisted value" do

          let!(:person) do
            Person.instantiate("pets" => false)
          end

          it "returns false" do
            person.send(:attribute_changed?, "pets").should be_false
          end
        end
      end

      context "when the attribute is an array" do

        let!(:person) do
          Person.new(aliases: [ "Bond" ])
        end

        context "when the array is only accessed" do

          before do
            person.move_changes
            person.aliases
          end

          it "returns false" do
            person.should_not be_aliases_changed
          end
        end
      end

      context "when the attribute is a hash" do

        let!(:person) do
          Person.new(map: { key: "value" })
        end

        context "when the hash is only accessed" do

          before do
            person.move_changes
            person.map
          end

          it "returns false" do
            person.should_not be_map_changed
          end
        end
      end
    end
  end

  describe "#attribute_changed_from_default?" do

    context "when the attribute differs from the default value" do

      let(:person) do
        Person.new(age: 33)
      end

      it "returns true" do
        person.should be_age_changed_from_default
      end
    end

    context "when the attribute is the same as the default" do

      let(:person) do
        Person.new
      end

      it "returns false" do
        person.should_not be_age_changed_from_default
      end
    end
  end

  describe "#attribute_was" do

    context "when the attribute has changed from the persisted value" do

      let(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns the old value" do
        person.send(:attribute_was, "title").should eq("Grand Poobah")
      end

      it "allows access via (attribute)_was" do
        person.title_was.should eq("Grand Poobah")
      end
    end

    context "when the attribute has changed from the default value" do

      let(:person) do
        Person.new
      end

      before do
        person.pets = true
      end

      it "returns the default value" do
        person.send(:attribute_was, "pets").should be_false
      end

      it "allows access via (attribute)_was" do
        person.pets_was.should be_false
      end
    end

    context "when the attribute has not changed from the persisted value" do

      let!(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      it "returns the original value" do
        person.send(:attribute_was, "title").should eq("Grand Poobah")
      end
    end

    context "when the attribute has not changed from the default value" do

      let(:person) do
        Person.new
      end

      it "returns the default value" do
        person.send(:attribute_was, "pets").should be_false
      end
    end
  end

  describe "#attribute_will_change!" do

    let(:aliases) do
      [ "007" ]
    end

    let(:person) do
      Person.new(aliases: aliases)
    end

    before do
      person.changed_attributes.clear
    end

    context "when the value has not changed" do

      before do
        person.aliases_will_change!
      end

      let(:changes) do
        person.changes
      end

      it "returns the value in the changes" do
        changes.should eq({ "aliases" => nil })
      end

      it "is not flagged as changed" do
        person.should_not be_changed
      end
    end

    context "when the value has changed" do

      before do
        person.aliases_will_change!
        person.aliases << "008"
      end

      let(:changes) do
        person.changes
      end

      it "returns the value in the changes" do
        changes.should eq({ "aliases" => [[ "007" ], [ "007", "008" ]] })
      end
    end

    context "when the value is duplicable" do

      context "when the attribute has not been cloned" do

        before do
          person.aliases_will_change!
        end

        let(:changed) do
          person.changed_attributes
        end

        it "clones the value" do
          changed["aliases"].should_not equal(aliases)
        end

        it "puts the old value in the changes" do
          changed["aliases"].should eq(aliases)
        end
      end

      context "when the attribute has been flagged" do

        before do
          person.changed_attributes["aliases"] = aliases
          aliases.expects(:clone).never
          person.aliases_will_change!
        end

        let(:changed) do
          person.changed_attributes
        end

        it "does not clone the value" do
          changed["aliases"].should equal(aliases)
        end

        it "retains the first value in the changes" do
          changed["aliases"].should eq(aliases)
        end
      end
    end
  end

  describe "#changed" do

    context "when the document has changed" do

      let(:person) do
        Person.instantiate(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns an array of changed field names" do
        person.changed.should include("title")
      end
    end

    context "when the document has not changed" do

      let(:person) do
        Person.instantiate({})
      end

      it "does not include non changed fields" do
        person.changed.should_not include("title")
      end
    end
  end

  describe "#changed?" do

    context "when the document has changed" do

      let(:person) do
        Person.new(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns true" do
        person.should be_changed
      end
    end

    context "when a hash field has been accessed" do

      context "when the field has not changed" do

        let(:person) do
          Person.create(map: { name: "value" })
        end

        before do
          person.map
        end

        it "returns false" do
          person.should_not be_changed
        end
      end

      context "when the field is changed" do

        let(:person) do
          Person.create(map: { name: "value" })
        end

        before do
          person.map = { name: "another" }
        end

        it "returns true" do
          person.should be_changed
        end
      end
    end

    context "when the document has not changed" do

      let(:acolyte) do
        Acolyte.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns false" do
        acolyte.should_not be_changed
      end
    end

    context "when a child has changed" do

      let(:person) do
        Person.create
      end

      let!(:address) do
        person.addresses.create(street: "hobrecht")
      end

      before do
        address.number = 10
      end

      it "returns true" do
        person.should be_changed
      end
    end

    context "when a deeply embedded child has changed" do

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "hobrecht")
      end

      let!(:location) do
        address.locations.create(name: "home")
      end

      before do
        location.name = "work"
      end

      it "returns true" do
        person.should be_changed
      end
    end

    context "when a child is new" do

      let(:person) do
        Person.create
      end

      let!(:address) do
        person.addresses.build(street: "hobrecht")
      end

      it "returns true" do
        person.should be_changed
      end
    end

    context "when a deeply embedded child is new" do

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "hobrecht")
      end

      let!(:location) do
        address.locations.build(name: "home")
      end

      it "returns true" do
        person.should be_changed
      end
    end
  end

  describe "#changes" do

    context "when the document has changed" do

      let(:person) do
        Person.instantiate(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns a hash of changes" do
        person.changes["title"].should eq(
          [ nil, "Captain Obvious" ]
        )
      end

      it "returns a hash with indifferent access" do
        person.changes[:title].should eq(
          [ nil, "Captain Obvious" ]
        )
      end
    end

    context "when the document has not changed" do

      let(:acolyte) do
        Acolyte.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns an empty hash" do
        acolyte.changes.should be_empty
      end
    end
  end

  describe "#setters" do

    context "when the document has changed" do

      let(:person) do
        Person.new(aliases: [ "007" ]).tap do |p|
          p.new_record = false
          p.move_changes
        end
      end

      context "when an array field has changed" do

        context "when the array has values removed" do

          before do
            person.aliases.delete_one("007")
          end

          let!(:setters) do
            person.setters
          end

          it "contains array changes in the setters" do
            setters.should eq({ "aliases" => [] })
          end
        end

        context "when the array has values added" do

          before do
            person.aliases << "008"
          end

          let!(:setters) do
            person.setters
          end

          it "contains array changes in the setters" do
            setters.should eq({ "aliases" => [ "007", "008" ] })
          end
        end

        context "when the array has changed completely" do

          before do
            person.aliases << "008"
            person.aliases.delete_one("007")
          end

          let!(:setters) do
            person.setters
          end

          it "does not contain array changes in the setters" do
            setters.should eq({ "aliases" => [ "008" ]})
          end
        end
      end

      context "when the document is a root document" do

        let(:person) do
          Person.instantiate(title: "Grand Poobah")
        end

        before do
          person.title = "Captain Obvious"
        end

        it "returns a hash of field names and new values" do
          person.setters["title"].should eq("Captain Obvious")
        end
      end

      context "when the document is embedded" do

        let(:person) do
          Person.instantiate(title: "Grand Poobah")
        end

        let(:address) do
          Address.instantiate(street: "Oxford St")
        end

        before do
          person.addresses << address
          person.instance_variable_set(:@new_record, false)
          address.instance_variable_set(:@new_record, false)
          address.street = "Bond St"
        end

        it "returns a hash of field names and new values" do
          address.setters.should eq(
            { "addresses.0.street" => "Bond St" }
          )
        end

        context "when the document is embedded multiple levels" do

          let(:location) do
            Location.new(name: "Home")
          end

          before do
            location.instance_variable_set(:@new_record, false)
            address.locations << location
            location.name = "Work"
          end

          it "returns the proper hash with locations" do
            location.setters.should eq(
              { "addresses.0.locations.0.name" => "Work" }
            )
          end
        end
      end
    end

    context "when the document has not changed" do

      let(:acolyte) do
        Acolyte.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns an empty hash" do
        acolyte.setters.should be_empty
      end
    end
  end

  describe "#previous_changes" do

    let(:person) do
      Person.new(title: "Grand Poobah")
    end

    before do
      person.title = "Captain Obvious"
    end

    context "when the document has been saved" do

      before do
        person.save!
      end

      it "returns the changes before the save" do
        person.previous_changes["title"].should eq(
          [ nil, "Captain Obvious" ]
        )
      end
    end

    context "when the document has not been saved" do

      it "returns an empty hash" do
        person.previous_changes.should be_empty
      end
    end
  end

  describe "#move_changes" do

    let(:person) do
      Person.new(title: "Sir")
    end

    before do
      person.atomic_pulls["addresses"] = Address.new
      person.atomic_unsets << Address.new
      person.delayed_atomic_sets["addresses"] = Address.new
      person.move_changes
    end

    it "clears the atomic pulls" do
      person.atomic_pulls.should be_empty
    end

    it "clears the atomic unsets" do
      person.atomic_unsets.should be_empty
    end

    it "clears the delayed atomic sets" do
      person.delayed_atomic_sets.should be_empty
    end

    it "clears the changed attributes" do
      person.changed_attributes.should be_empty
    end
  end

  describe "#reset_attribute!" do

    context "when the attribute has changed" do

      let(:person) do
        Person.instantiate(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
        person.send(:reset_attribute!, "title")
      end

      it "resets the value to the original" do
        person.title.should be_nil
      end

      it "allows access via reset_(attribute)!" do
        person.title.should be_nil
      end

      it "removes the field from the changes" do
        person.changed.should include("title")
      end
    end

    context "when the attribute has not changed" do

      let(:person) do
        Person.instantiate(title: "Grand Poobah")
      end

      before do
        person.send(:reset_attribute!, "title")
      end

      it "does nothing" do
        person.title.should be_nil
      end
    end
  end

  context "when fields have been defined pre-dirty inclusion" do

    let(:document) do
      Dokument.new
    end

    it "defines a _change method" do
      document.updated_at_change.should be_nil
    end

    it "defines a _changed? method" do
      document.updated_at_changed?.should be_false
    end

    it "defines a _changes method" do
      document.updated_at_was.should be_nil
    end
  end

  context "when only embedded documents change" do

    let!(:person) do
      Person.create
    end

    context "when the child is an embeds one" do

      context "when the child is new" do

        let!(:name) do
          person.build_name(first_name: "Gordon", last_name: "Ramsay")
        end

        it "flags the parent as changed" do
          person.should be_changed
        end
      end

      context "when the child is modified" do

        let!(:name) do
          person.create_name(first_name: "Gordon", last_name: "Ramsay")
        end

        before do
          name.first_name = "G"
        end

        it "flags the parent as changed" do
          person.should be_changed
        end
      end

      context "when the child is not modified" do

        let!(:name) do
          person.create_name(first_name: "Gordon", last_name: "Ramsay")
        end

        it "does not flag the parent as changed" do
          person.should_not be_changed
        end
      end
    end

    context "when the child is an embeds many" do

      context "when a child is new" do

        let!(:address) do
          person.addresses.build(street: "jakobstr.")
        end

        it "flags the parent as changed" do
          person.should be_changed
        end
      end

      context "when a child is modified" do

        let!(:address) do
          person.addresses.create(street: "jakobstr.")
        end

        before do
          address.city = "Berlin"
        end

        it "flags the parent as changed" do
          person.should be_changed
        end
      end

      context "when no child is modified" do

        let!(:address) do
          person.addresses.create(street: "skalitzerstr.")
        end

        it "does not flag the parent as changed" do
          person.should_not be_changed
        end
      end
    end
  end

  context "when changing a hash of hashes" do

    let!(:person) do
      Person.create(map: { "test" => {}})
    end

    before do
      person.map["test"]["value"] = 10
    end

    it "records the changes" do
      person.changes.should eq(
        { "map" => [{ "test" => {}}, { "test" => { "value" => 10 }}]}
      )
    end
  end

  context "when modifying a many to many key" do

    let!(:person) do
      Person.create
    end

    let!(:preference) do
      Preference.create(name: "dirty")
    end

    before do
      person.update_attributes(preference_ids: [ preference.id ])
    end

    it "records the foreign key dirty changes" do
      person.previous_changes["preference_ids"].should eq(
        [[], [ preference.id ]]
      )
    end
  end

  context "when accessing an array field" do

    let!(:person) do
      Person.create
    end

    let(:from_db) do
      Person.find(person.id)
    end

    context "when the field is not changed" do

      before do
        from_db.preference_ids
      end

      it "does not get marked as dirty" do
        from_db.changes["preference_ids"].should be_nil
      end
    end
  end

  context "when reloading an unchanged document" do

    let!(:person) do
      Person.create
    end

    let(:from_db) do
      Person.find(person.id)
    end

    before do
      from_db.reload
    end

    it "clears the changed attributes" do
      from_db.changed_attributes.should be_empty
    end
  end

  context "when fields are getting changed" do

    let(:person) do
      Person.create(
        title: "MC",
        some_dynamic_field: 'blah'
      )
    end

    before do
      person.title = "DJ"
      person.write_attribute(:ssn, "222-22-2222")
      person.some_dynamic_field = 'bloop'
    end

    it "marks the document as changed" do
      person.should be_changed
    end

    it "marks field changes" do
      person.changes.should eq({
        "title" => [ "MC", "DJ" ],
        "ssn" => [ nil, "222-22-2222" ],
        "some_dynamic_field" => [ "blah", "bloop" ]
      })
    end

    it "marks changed fields" do
      person.changed.should =~ [ "title", "ssn", "some_dynamic_field" ]
    end

    it "marks the field as changed" do
      person.title_changed?.should be_true
    end

    it "stores previous field values" do
      person.title_was.should eq("MC")
    end

    it "marks field changes" do
      person.title_change.should eq([ "MC", "DJ" ])
    end

    it "allows reset of field changes" do
      person.reset_title!
      person.title.should eq("MC")
      person.changed.should =~ [ "ssn", "some_dynamic_field", "title" ]
    end

    context "after a save" do

      before do
        person.save!
      end

      it "clears changes" do
        person.should_not be_changed
      end

      it "stores previous changes" do
        person.previous_changes["title"].should eq([ "MC", "DJ" ])
        person.previous_changes["ssn"].should eq([ nil, "222-22-2222" ])
      end
    end

    context "when the previous value is nil" do

      before do
        person.score = 100
        person.reset_score!
      end

      it "removes the attribute from the document" do
        person.score.should be_nil
      end
    end
  end

  context "when accessing dirty attributes in callbacks" do

    context "when the document is persisted" do

      let!(:acolyte) do
        Acolyte.create(name: "callback-test")
      end

      before do
        Acolyte.set_callback(:save, :after, if: :callback_test?) do |doc|
          doc[:changed_in_callback] = doc.changes.dup
        end
      end

      after do
        Acolyte._save_callbacks.reject! do |callback|
          callback.kind == :after
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.update_attribute(:status, "testing")
        acolyte.changed_in_callback.should eq({ "status" => [ nil, "testing" ] })
      end
    end

    context "when the document is new" do

      let!(:acolyte) do
        Acolyte.new(name: "callback-test")
      end

      before do
        Acolyte.set_callback(:save, :after, if: :callback_test?) do |doc|
          doc[:changed_in_callback] = doc.changes.dup
        end
      end

      after do
        Acolyte._save_callbacks.reject! do |callback|
          callback.kind == :after
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.save
        acolyte.changed_in_callback["name"].should eq([ nil, "callback-test" ])
      end
    end
  end

  context "when associations are getting changed" do

    let(:person) do
      Person.create(addresses: [ Address.new ])
    end

    before do
      person.addresses = [ Address.new ]
    end

    it "does not set the association to nil when hitting the database" do
      person.setters.should_not eq({ "addresses" => nil })
    end
  end
end
