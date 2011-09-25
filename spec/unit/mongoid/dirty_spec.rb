require "spec_helper"

describe Mongoid::Dirty do

  context "when fields have been defined pre-dirty inclusion" do

    let(:person) do
      Person.new
    end

    it "defines a _change method" do
      person.updated_at_change.should be_nil
    end

    it "defines a _changed? method" do
      person.updated_at_changed?.should eq(false)
    end

    it "defines a _changes method" do
      person.updated_at_was.should be_nil
    end
  end

  describe "#attribute_change" do

    context "when the attribute has changed from the persisted value" do

      let(:person) do
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
        Person.new(:pets => true)
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
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
          Person.new(:aliases => [ "Grand Poobah" ]).tap(&:move_changes)
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
          Person.new(:map => { :location => "Home" }).tap(&:move_changes)
        end

        before do
          person.map[:location] = "Work"
        end

        it "returns an array of the original value and new value" do
          person.send(:attribute_change, "map").should eq(
            [{ :location => "Home" }, { :location => "Work" }]
          )
        end

        it "allows access via (attribute)_change" do
          person.map_change.should eq(
            [{ :location => "Home" }, { :location => "Work" }]
          )
        end

        context "when the attribute changes multiple times" do

          before do
            person.map[:lat] = 20.0
          end

          it "returns an array of the original value and new value" do
            person.send(:attribute_change, "map").should eq(
              [{ :location => "Home" }, { :location => "Work", :lat => 20.0 }]
            )
          end
        end
      end
    end

    context "when the attribute has not changed from the persisted value" do

      let(:person) do
        Person.new(:title => nil)
      end

      it "returns nil" do
        person.send(:attribute_change, "title").should be_nil
      end
    end

    context "when the attribute has not changed from the default value" do
      let(:person) do
        Person.new
      end

      it "returns nil" do
        person.send(:attribute_change, "pets").should be_nil
      end
    end

    context "when the attribute has been set with the same value" do

      let(:person) do
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
        Person.new(:title => "Grand Poobah")
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
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
      end

      it "returns false" do
        person.send(:attribute_changed?, "title").should be_false
      end
    end

    context "when the attribute has not changed from the default value" do

      context "when the attribute is not enumerable" do

        let!(:person) do
          Person.new
        end

        it "returns false" do
          person.send(:attribute_changed?, "pets").should be_false
        end
      end

      context "when the attribute is an array" do

        let!(:person) do
          Person.new(:aliases => [ "Bond" ])
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
          Person.new(:map => { :key => "value" })
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

  describe "#attribute_was" do

    context "when the attribute has changed from the persisted value" do

      let(:person) do
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
        Person.new(:title => "Grand Poobah").tap(&:move_changes)
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
      Person.new(:aliases => aliases)
    end

    before do
      person.changed_attributes.clear
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
        Person.instantiate(:title => "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns an array of changed field names" do
        person.changed.should eq([ "title" ])
      end
    end

    context "when the document has not changed" do

      let(:person) do
        Person.instantiate({})
      end

      it "returns an empty array" do
        person.changed.should eq([])
      end
    end
  end

  describe "#changed?" do

    context "when the document has changed" do

      let(:person) do
        Person.new(:title => "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns true" do
        person.should be_changed
      end
    end

    context "when the document has not changed" do

      let(:person) do
        Person.instantiate
      end

      it "returns false" do
        person.should_not be_changed
      end
    end
  end

  describe "#changes" do

    context "when the document has changed" do

      let(:person) do
        Person.instantiate(:title => "Grand Poobah")
      end

      before do
        person.title = "Captain Obvious"
      end

      it "returns a hash of changes" do
        person.changes.should eq(
          { "title" => [ nil, "Captain Obvious" ] }
        )
      end
    end

    context "when the document has not changed" do

      let(:person) do
        Person.instantiate
      end

      it "returns an empty hash" do
        person.changes.should be_empty
      end
    end
  end

  describe "#setters" do

    context "when the document has changed" do

      context "when the document is a root document" do

        let(:person) do
          Person.instantiate(:title => "Grand Poobah")
        end

        before do
          person.title = "Captain Obvious"
        end

        it "returns a hash of field names and new values" do
          person.setters.should eq(
            { "title" => "Captain Obvious" }
          )
        end
      end

      context "when the document is embedded" do

        let(:person) do
          Person.instantiate(:title => "Grand Poobah")
        end

        let(:address) do
          Address.instantiate(:street => "Oxford St")
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
            Location.new(:name => "Home")
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

      let(:person) do
        Person.instantiate
      end

      it "returns an empty hash" do
        person.setters.should be_empty
      end
    end
  end

  describe "#previous_changes" do

    let(:person) do
      Person.new(:title => "Grand Poobah")
    end

    before do
      person.title = "Captain Obvious"
    end

    context "when the document has been saved" do

      before do
        person.collection.expects(:insert).returns(true)
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
        person.previous_changes.should be_nil
      end
    end
  end

  describe "#reset_attribute!" do

    context "when the attribute has changed" do

      let(:person) do
        Person.instantiate(:title => "Grand Poobah")
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
        person.changed.should eq([ "title" ])
      end
    end

    context "when the attribute has not changed" do

      let(:person) do
        Person.instantiate(:title => "Grand Poobah")
      end

      before do
        person.send(:reset_attribute!, "title")
      end

      it "does nothing" do
        person.title.should be_nil
      end
    end
  end
end
