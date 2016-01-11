require "spec_helper"

describe Mongoid::Changeable do

  describe "#attribute_change" do

    context "when the attribute has changed from the persisted value" do

      context "when using the setter" do

        let(:person) do
          Person.new(title: "Grand Poobah").tap(&:move_changes)
        end

        before do
          person.title = "Captain Obvious"
        end

        it "returns an array of the old value and new value" do
          expect(person.send(:attribute_change, "title")).to eq(
            [ "Grand Poobah", "Captain Obvious" ]
          )
        end

        it "allows access via (attribute)_change" do
          expect(person.title_change).to eq(
            [ "Grand Poobah", "Captain Obvious" ]
          )
        end

        context "when the field is aliased" do

          let(:person) do
            Person.new(test: "Aliased 1").tap(&:move_changes)
          end

          before do
            person.test = "Aliased 2"
          end

          it "returns an array of the old value and new value" do
            expect(person.send(:attribute_change, "test")).to eq(
              [ "Aliased 1", "Aliased 2" ]
            )
          end

          it "allows access via (attribute)_change" do
            expect(person.test_change).to eq(
              [ "Aliased 1", "Aliased 2" ]
            )
          end
        end
      end

      context "when using [] methods" do

        let(:person) do
          Person.new(title: "Grand Poobah").tap(&:move_changes)
        end

        before do
          person[:title] = "Captain Obvious"
        end

        it "returns an array of the old value and new value" do
          expect(person.send(:attribute_change, "title")).to eq(
            [ "Grand Poobah", "Captain Obvious" ]
          )
        end

        it "allows access via (attribute)_change" do
          expect(person.title_change).to eq(
            [ "Grand Poobah", "Captain Obvious" ]
          )
        end
      end
    end

    context "when the attribute has changed from the default value" do

      context "when using the setter" do

        let(:person) do
          Person.new(pets: true)
        end

        it "returns an array of nil and new value" do
          expect(person.send(:attribute_change, "pets")).to eq([ nil, true ])
        end

        it "allows access via (attribute)_change" do
          expect(person.pets_change).to eq([ nil, true ])
        end
      end

      context "when using [] methods" do

        context "when the field is defined" do

          let(:person) do
            Person.new
          end

          before do
            person[:pets] = true
          end

          it "returns an array of nil and new value" do
            expect(person.send(:attribute_change, "pets")).to eq([ nil, true ])
          end

          it "allows access via (attribute)_change" do
            expect(person.pets_change).to eq([ nil, true ])
          end
        end

        context "when the field is not defined" do

          let(:person) do
            Person.new
          end

          before do
            person[:t] = "test"
          end

          it "returns an array of nil and new value" do
            expect(person.send(:attribute_change, "t")).to eq([ nil, "test" ])
          end
        end
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
        expect(person.send(:attribute_change, "title")).to eq(
          [ "Grand Poobah", "Dark Helmet" ]
        )
      end

      it "allows access via (attribute)_change" do
        expect(person.title_change).to eq(
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
          expect(person.send(:attribute_change, "aliases")).to eq(
            [[ "Grand Poobah" ],  [ "Dark Helmet" ]]
          )
        end

        it "allows access via (attribute)_change" do
          expect(person.aliases_change).to eq(
            [[ "Grand Poobah" ],  [ "Dark Helmet" ]]
          )
        end

        context "when the attribute changes multiple times" do

          before do
            person.aliases << "Colonel Sanders"
          end

          it "returns an array of the original value and new value" do
            expect(person.send(:attribute_change, "aliases")).to eq(
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
          expect(person.send(:attribute_change, "map")).to eq(
            [{ location: "Home" }, { location: "Work" }]
          )
        end

        it "allows access via (attribute)_change" do
          expect(person.map_change).to eq(
            [{ location: "Home" }, { location: "Work" }]
          )
        end

        context "when the attribute changes multiple times" do

          before do
            person.map[:lat] = 20.0
          end

          it "returns an array of the original value and new value" do
            expect(person.send(:attribute_change, "map")).to eq(
              [{ location: "Home" }, { location: "Work", lat: 20.0 }]
            )
          end
        end

        context "when the values are arrays" do

          let(:map) do
            {
              "stack1" => [ 1, 2, 3, 4 ],
              "stack2" => [ 1, 2, 3, 4 ],
              "stack3" => [ 1, 2, 3, 4 ]
            }
          end

          before do
            person.map = map
            person.move_changes
          end

          context "when reordering the arrays inline" do

            before do
              person.map["stack1"].reverse!
            end

            it "flags the attribute as changed" do
              expect(person.send(:attribute_change, "map")).to eq(
                [
                  {
                    "stack1" => [ 1, 2, 3, 4 ],
                    "stack2" => [ 1, 2, 3, 4 ],
                    "stack3" => [ 1, 2, 3, 4 ]
                  },
                  {
                    "stack1" => [ 4, 3, 2, 1 ],
                    "stack2" => [ 1, 2, 3, 4 ],
                    "stack3" => [ 1, 2, 3, 4 ]
                  },
                ]
              )
            end
          end
        end
      end
    end

    context "when the attribute has not changed from the persisted value" do

      let(:person) do
        Person.new(title: nil)
      end

      it "returns nil" do
        expect(person.send(:attribute_change, "title")).to be_nil
      end
    end

    context "when the attribute has not changed from the default value" do

      context "when the attribute differs from the persisted value" do

        let(:person) do
          Person.new
        end

        it "returns the change" do
          expect(person.send(:attribute_change, "pets")).to eq([ nil, false ])
        end
      end

      context "when the attribute does not differ from the persisted value" do

        let(:person) do
          Person.instantiate("pets" => false)
        end

        it "returns nil" do
          expect(person.send(:attribute_change, "pets")).to be_nil
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
        expect(person.send(:attribute_change, "title")).to be_nil
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
        expect(person.send(:attribute_change, "title")).to eq(
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
        expect(person.send(:attribute_changed?, "title")).to be true
      end

      it "allows access via (attribute)_changed?" do
        expect(person.title_changed?).to be true
      end

      context "when the field is aliased" do

        let(:person) do
          Person.new(test: "Aliased 1")
        end

        before do
          person.test = "Aliased 2"
        end

        it "returns true" do
          expect(person.send(:attribute_changed?, "test")).to be true
        end

        it "allows access via (attribute)_changed?" do
          expect(person.test_changed?).to be true
        end
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
        expect(person.send(:attribute_changed?, "pets")).to be true
      end

      it "allows access via (attribute)_changed?" do
        expect(person.pets_changed?).to be true
      end
    end

    context "when the attribute has not changed the persisted value" do

      let!(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      it "returns false" do
        expect(person.send(:attribute_changed?, "title")).to be false
      end
    end

    context "when the attribute has not changed from the default value" do

      context "when the attribute is not enumerable" do

        context "when the attribute differs from the persisted value" do

          let!(:person) do
            Person.new
          end

          it "returns true" do
            expect(person.send(:attribute_changed?, "pets")).to be true
          end
        end

        context "when the attribute does not differ from the persisted value" do

          let!(:person) do
            Person.instantiate("pets" => false)
          end

          it "returns false" do
            expect(person.send(:attribute_changed?, "pets")).to be false
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
            expect(person).to_not be_aliases_changed
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
            expect(person).to_not be_map_changed
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
        expect(person).to be_age_changed_from_default
      end
    end

    context "when the attribute is the same as the default" do

      let(:person) do
        Person.new
      end

      it "returns false" do
        expect(person).to_not be_age_changed_from_default
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
        expect(person.send(:attribute_was, "title")).to eq("Grand Poobah")
      end

      it "allows access via (attribute)_was" do
        expect(person.title_was).to eq("Grand Poobah")
      end

      context "when the field is aliased" do

        let(:person) do
          Person.new(test: "Aliased 1").tap(&:move_changes)
        end

        before do
          person.test = "Aliased 2"
        end

        it "returns the old value" do
          expect(person.send(:attribute_was, "test")).to eq("Aliased 1")
        end

        it "allows access via (attribute)_was" do
          expect(person.test_was).to eq("Aliased 1")
        end
      end
    end

    context "when the attribute has not changed from the persisted value" do

      let!(:person) do
        Person.new(title: "Grand Poobah").tap(&:move_changes)
      end

      it "returns the original value" do
        expect(person.send(:attribute_was, "title")).to eq("Grand Poobah")
      end
    end
  end

  describe "#attribute_will_change!" do

    let(:aliases) do
      [ "007" ]
    end

    let(:person) do
      Person.new(aliases: aliases, test: "Aliased 1")
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

      it "does not return the value in the changes" do
        expect(changes).to be_empty
      end

      it "is not flagged as changed" do
        expect(person).to_not be_changed
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
        expect(changes).to eq({ "aliases" => [[ "007" ], [ "007", "008" ]] })
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
          expect(changed["aliases"]).to_not equal(aliases)
        end

        it "puts the old value in the changes" do
          expect(changed["aliases"]).to eq(aliases)
        end
      end

      context "when the attribute has been flagged" do

        before do
          person.changed_attributes["aliases"] = aliases
          expect(aliases).to receive(:clone).never
          person.aliases_will_change!
        end

        let(:changed) do
          person.changed_attributes
        end

        it "does not clone the value" do
          expect(changed["aliases"]).to equal(aliases)
        end

        it "retains the first value in the changes" do
          expect(changed["aliases"]).to eq(aliases)
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
        expect(person.changed).to include("title")
      end

    end

    context "When the document has changed but changed back to the original" do

      let(:person) do
        Person.instantiate(title: "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
        person.title = nil
      end

      it "returns an array of changed field names" do
        expect(person.changed).not_to include("title")
      end

    end

    context "when the document has not changed" do

      let(:person) do
        Person.instantiate({})
      end

      it "does not include non changed fields" do
        expect(person.changed).to_not include("title")
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let!(:name) do
        person.create_name(first_name: "Layne", last_name: "Staley")
      end

      context "when changing attributes via []" do

        before do
          person.name["a"] = "testing"
        end

        it "returns true" do
          expect(person.name).to be_changed
        end
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
        expect(person).to be_changed
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
          expect(person).to_not be_changed
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
          expect(person).to be_changed
        end
      end

      context "when a dynamic field is changed in place" do

        let(:person) do
          Person.create(other_name: { full: {first: 'first', last: 'last'} })
        end

        before do
          person.other_name[:full][:first] = 'Name'
        end

        it "returns true" do
          expect(person.changes).to_not be_empty
          expect(person).to be_changed
        end
      end
    end

    context "when the document has not changed" do

      let(:acolyte) do
        Acolyte.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns false" do
        expect(acolyte).to_not be_changed
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
        expect(person).to be_changed
      end
    end

    context "when changed? has been called before child elements size change" do

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
        person.changed?
      end

      context "when adding via new" do

        before do
          address.locations.new
        end

        it "returns true" do
          expect(person).to be_changed
        end
      end

      context "when adding via build" do

        before do
          address.locations.build
        end

        it "returns true" do
          expect(person).to be_changed
        end
      end

      context "when adding via create" do

        before do
          address.locations.create
        end

        it "returns false" do
          expect(person).to_not be_changed
        end
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
        expect(person).to be_changed
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
        expect(person).to be_changed
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
        expect(person).to be_changed
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
        expect(person.changes["title"]).to eq(
          [ nil, "Captain Obvious" ]
        )
      end

      it "returns a hash with indifferent access" do
        expect(person.changes[:title]).to eq(
          [ nil, "Captain Obvious" ]
        )
      end
    end

    context "when the document has not changed" do

      let(:acolyte) do
        Acolyte.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns an empty hash" do
        expect(acolyte.changes).to be_empty
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
            expect(setters).to eq({ "aliases" => [] })
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
            expect(setters).to eq({ "aliases" => [ "007", "008" ] })
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
            expect(setters).to eq({ "aliases" => [ "008" ]})
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
          expect(person.setters["title"]).to eq("Captain Obvious")
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
          expect(address.setters).to eq(
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
            expect(location.setters).to eq(
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
        expect(acolyte.setters).to be_empty
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
        expect(person.previous_changes["title"]).to eq(
          [ nil, "Captain Obvious" ]
        )
      end
    end

    context "when the document has not been saved" do

      it "returns an empty hash" do
        expect(person.previous_changes).to be_empty
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
      expect(person.atomic_pulls).to be_empty
    end

    it "clears the atomic unsets" do
      expect(person.atomic_unsets).to be_empty
    end

    it "clears the delayed atomic sets" do
      expect(person.delayed_atomic_sets).to be_empty
    end

    it "clears the changed attributes" do
      expect(person.changed_attributes).to be_empty
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
        expect(person.title).to be_nil
      end

      it "allows access via reset_(attribute)!" do
        expect(person.title).to be_nil
      end

      it "removes the field from the changes" do
        expect(person.changed).to_not include("title")
      end

      context "when the field is aliased" do

        let(:person) do
          Person.instantiate(test: "Aliased 1")
        end

        before do
          person.test = "Aliased 2"
          person.send(:reset_attribute!, "test")
        end

        it "resets the value to the original" do
          expect(person.test).to be_nil
        end

        it "removes the field from the changes" do
          expect(person.changed).to_not include("test")
        end
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
        expect(person.title).to be_nil
      end
    end
  end

  describe "#reset_attribute_to_default!" do

    context "when a default is defined" do

      context "when the document is new" do

        let(:person) do
          Person.new(pets: true)
        end

        before do
          person.reset_pets_to_default!
        end

        it "resets to the default value" do
          expect(person.pets).to eq(false)
        end
      end

      context "when the document is persisted" do

        let(:person) do
          Person.create(pets: true)
        end

        before do
          person.reset_pets_to_default!
        end

        it "resets to the default value" do
          expect(person.pets).to eq(false)
        end

        it "flags the document dirty" do
          expect(person).to be_pets_changed
        end
      end
    end

    context "when a default is not defined" do

      context "when the document is new" do

        let(:person) do
          Person.new(title: "test")
        end

        before do
          person.reset_title_to_default!
        end

        it "resets to nil" do
          expect(person.title).to be_nil
        end
      end

      context "when the document is persisted" do

        let(:person) do
          Person.create(title: "test")
        end

        before do
          person.reset_title_to_default!
        end

        it "resets to nil" do
          expect(person.title).to be_nil
        end

        it "flags the document dirty" do
          expect(person).to be_title_changed
        end
      end
    end
  end

  context "when fields have been defined pre-dirty inclusion" do

    let(:document) do
      Dokument.new
    end

    it "defines a _change method" do
      expect(document.updated_at_change).to be_nil
    end

    it "defines a _changed? method" do
      expect(document.updated_at_changed?).to be false
    end

    it "defines a _changes method" do
      expect(document.updated_at_was).to be_nil
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
          expect(person).to be_changed
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
          expect(person).to be_changed
        end
      end

      context "when the child is not modified" do

        let!(:name) do
          person.create_name(first_name: "Gordon", last_name: "Ramsay")
        end

        it "does not flag the parent as changed" do
          expect(person).to_not be_changed
        end
      end
    end

    context "when the child is an embeds many" do

      context "when a child is new" do

        let!(:address) do
          person.addresses.build(street: "jakobstr.")
        end

        it "flags the parent as changed" do
          expect(person).to be_changed
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
          expect(person).to be_changed
        end
      end

      context "when no child is modified" do

        let!(:address) do
          person.addresses.create(street: "skalitzerstr.")
        end

        it "does not flag the parent as changed" do
          expect(person).to_not be_changed
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
      expect(person.changes).to eq(
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
      expect(person.previous_changes["preference_ids"]).to eq(
        [nil, [ preference.id ]]
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

      it "flags the change" do
        expect(from_db.changes["preference_ids"]).to eq([ nil, []])
      end

      it "does not include the changes in the setters" do
        expect(from_db.setters).to be_empty
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
      expect(from_db.changed_attributes).to be_empty
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
      expect(person).to be_changed
    end

    it "marks field changes" do
      expect(person.changes).to eq({
        "title" => [ "MC", "DJ" ],
        "ssn" => [ nil, "222-22-2222" ],
        "some_dynamic_field" => [ "blah", "bloop" ]
      })
    end

    it "marks changed fields" do
      expect(person.changed).to eq([ "title", "ssn", "some_dynamic_field" ])
    end

    it "marks the field as changed" do
      expect(person.title_changed?).to be true
    end

    it "stores previous field values" do
      expect(person.title_was).to eq("MC")
    end

    it "marks field changes" do
      expect(person.title_change).to eq([ "MC", "DJ" ])
    end

    it "allows reset of field changes" do
      person.reset_title!
      expect(person.title).to eq("MC")
      expect(person.changed).to eq([ "ssn", "some_dynamic_field" ])
    end

    context "after a save" do

      before do
        person.save!
      end

      it "clears changes" do
        expect(person).to_not be_changed
      end

      it "stores previous changes" do
        expect(person.previous_changes["title"]).to eq([ "MC", "DJ" ])
        expect(person.previous_changes["ssn"]).to eq([ nil, "222-22-2222" ])
      end
    end

    context "when the previous value is nil" do

      before do
        person.score = 100
        person.reset_score!
      end

      it "removes the attribute from the document" do
        expect(person.score).to be_nil
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
        Acolyte._save_callbacks.select do |callback|
          callback.kind == :after
        end.each do |callback|
          Acolyte._save_callbacks.delete(callback)
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.update_attribute(:status, "testing")
        expect(acolyte.changed_in_callback).to eq({ "status" => [ nil, "testing" ] })
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
        Acolyte._save_callbacks.select do |callback|
          callback.kind == :after
        end.each do |callback|
          Acolyte._save_callbacks.delete(callback)
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.save
        expect(acolyte.changed_in_callback["name"]).to eq([ nil, "callback-test" ])
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
      expect(person.setters).to_not eq({ "addresses" => nil })
    end
  end

  context 'when nesting deeply embedded documents' do

    context 'when persisting the root document' do

      let!(:person) do
        Person.create
      end

      it 'is not marked as changed' do
        expect(person).to_not be_changed
      end

      context 'when creating a new first level embedded document' do

        let!(:address) do
          person.addresses.new(street: 'goltzstr.')
        end

        it 'flags the root document as changed' do
          expect(person).to be_changed
        end

        it 'flags the first level child as changed' do
          expect(address).to be_changed
        end

        context 'when building the lowest level document' do

          before do
            person.save
          end

          let!(:code) do
            address.build_code
          end

          it 'flags the root document as changed' do
            expect(person).to be_changed
          end

          it 'flags the first level embedded document as changed' do
            expect(address).to be_changed
          end

          it 'flags the lowest level embedded document as changed' do
            expect(code).to be_changed
          end

          context 'when saving the hierarchy' do

            before do
              person.save
            end

            let(:reloaded) do
              Person.find(person.id)
            end

            it 'saves the first embedded document' do
              expect(reloaded.addresses.first).to eq(address)
            end

            it 'saves the lowest level embedded document' do
              expect(reloaded.addresses.first.code).to eq(code)
            end

            context 'when embedding further' do

              let!(:deepest) do
                reloaded.addresses.first.code.build_deepest
              end

              before do
                reloaded.save
              end

              it 'saves the deepest embedded document' do
                expect(reloaded.reload.addresses.first.code.deepest).to eq(deepest)
              end
            end
          end
        end
      end
    end
  end
end
