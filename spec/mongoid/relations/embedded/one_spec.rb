require "spec_helper"

describe Mongoid::Relations::Embedded::One do

  describe "#===" do

    let(:base) do
      Person.new
    end

    let(:target) do
      Name.new
    end

    let(:metadata) do
      Person.relations["name"]
    end

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when the proxied document is same class" do

      it "returns true" do
        (relation === Name.new).should be_true
      end
    end
  end

  describe "#=" do

    context "when the relation is not cyclic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new
        end

        before do
          person.name = name
        end

        it "sets the target of the relation" do
          person.name.should eq(name)
        end

        it "sets the base on the inverse relation" do
          name.namable.should eq(person)
        end

        it "sets the same instance on the inverse relation" do
          name.namable.should eql(person)
        end

        it "does not save the target" do
          name.should_not be_persisted
        end

        context "with overwritten getter" do

          before do
            person.name = nil
            def person.name_with_default
              name_without_default or (self.name = Name.new)
            end
            class << person
              alias_method_chain :name, :default
            end
          end

          it "sets the target without an invinite recursion" do
            person.name = name
            person.name.should be_present
          end
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let(:name) do
          Name.new
        end

        context "when setting with a hash" do

          before do
            person.name = {}
          end

          let!(:child_name) do
            person.name
          end

          it "sets the target of the relation" do
            person.name.should eq(child_name)
          end

          it "sets the base on the inverse relation" do
            child_name.namable.should eq(person)
          end

          it "sets the same instance on the inverse relation" do
            child_name.namable.should eql(person)
          end

          it "saves the target" do
            child_name.should be_persisted
          end

          context "when replacing a relation with a hash" do

            before do
              person.name = {}
            end

            it "sets the relation with the proper object" do
              person.name.should be_a(Name)
            end
          end
        end

        context "when setting to the same document" do

          before do
            person.name = name
            person.name = person.name
          end

          it "does not change the relation" do
            person.name.should eq(name)
          end

          it "does not persist any change" do
            person.reload.name.should eq(name)
          end
        end

        context "when setting directly" do

          before do
            person.name = name
          end

          it "sets the target of the relation" do
            person.name.should eq(name)
          end

          it "sets the base on the inverse relation" do
            name.namable.should eq(person)
          end

          it "sets the same instance on the inverse relation" do
            name.namable.should eql(person)
          end

          it "saves the target" do
            name.should be_persisted
          end

          context "when replacing an exising document" do

            let(:pet_owner) do
              PetOwner.create
            end

            let(:pet_one) do
              Pet.new
            end

            let(:pet_two) do
              Pet.new
            end

            before do
              pet_owner.pet = pet_one
              pet_owner.pet = pet_two
            end

            it "runs the destroy callbacks on the old document" do
              pet_one.destroy_flag.should be_true
            end
          end
        end

        context "when setting via the parent attributes" do

          before do
            person.attributes = { name: name }
          end

          it "sets the target of the relation" do
            person.name.should eq(name)
          end

          it "does not save the target" do
            name.should_not be_persisted
          end
        end
      end
    end

    context "when the relation is cyclic" do

      context "when the parent is a new record" do

        let(:parent_shelf) do
          Shelf.new
        end

        let(:child_shelf) do
          Shelf.new
        end

        before do
          parent_shelf.child_shelf = child_shelf
        end

        it "sets the target of the relation" do
          parent_shelf.child_shelf.should eq(child_shelf)
        end

        it "sets the base on the inverse relation" do
          child_shelf.parent_shelf.should eq(parent_shelf)
        end

        it "sets the same instance on the inverse relation" do
          child_shelf.parent_shelf.should eql(parent_shelf)
        end

        it "does not save the target" do
          child_shelf.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:parent_shelf) do
          Shelf.create
        end

        let(:child_shelf) do
          Shelf.new
        end

        before do
          parent_shelf.child_shelf = child_shelf
        end

        it "sets the target of the relation" do
          parent_shelf.child_shelf.should eq(child_shelf)
        end

        it "sets the base on the inverse relation" do
          child_shelf.parent_shelf.should eq(parent_shelf)
        end

        it "sets the same instance on the inverse relation" do
          child_shelf.parent_shelf.should eql(parent_shelf)
        end

        it "saves the target" do
          child_shelf.should be_persisted
        end
      end
    end

    context "when setting a new document multiple times in a row" do

      let(:parent) do
        Parent.create
      end

      before do
        parent.first_child = Child.new
        parent.first_child = Child.new
        parent.first_child = Child.new
      end

      it "saves the child document" do
        parent.first_child.should be_a(Child)
      end
    end
  end

  describe "#= nil" do

    context "when the relation is not cyclic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new
        end

        before do
          person.name = name
          person.name = nil
        end

        it "sets the relation to nil" do
          person.name.should be_nil
        end

        it "removes the inverse relation" do
          name.namable.should be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:person) do
          Person.new
        end

        before do
          person.name = nil
        end

        it "sets the relation to nil" do
          person.name.should be_nil
        end
      end

      context "when the parent is persisted" do

        let(:person) do
          Person.create
        end

        let(:name) do
          Name.new
        end

        context "when setting directly" do

          before do
            person.name = name
            person.name = nil
          end

          it "sets the relation to nil" do
            person.name.should be_nil
          end

          it "removed the inverse relation" do
            name.namable.should be_nil
          end

          it "deletes the child document" do
            name.should be_destroyed
          end
        end

        context "when setting via parent attributes" do

          before do
            person.name = name
            person.attributes = { name: nil }
          end

          it "sets the relation to nil" do
            person.name.should be_nil
          end

          it "does not delete the child document" do
            name.should_not be_destroyed
          end
        end
      end
    end

    context "when the relation is cyclic" do

      context "when the parent is a new record" do

        let(:parent_shelf) do
          Shelf.new
        end

        let(:child_shelf) do
          Shelf.new
        end

        before do
          parent_shelf.child_shelf = child_shelf
          parent_shelf.child_shelf = nil
        end

        it "sets the relation to nil" do
          parent_shelf.child_shelf.should be_nil
        end

        it "removes the inverse relation" do
          child_shelf.parent_shelf.should be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:parent_shelf) do
          Shelf.new
        end

        before do
          parent_shelf.child_shelf = nil
        end

        it "sets the relation to nil" do
          parent_shelf.child_shelf.should be_nil
        end
      end

      context "when the documents are not new records" do

        let(:parent_shelf) do
          Shelf.create
        end

        let(:child_shelf) do
          Shelf.new
        end

        before do
          parent_shelf.child_shelf = child_shelf
          parent_shelf.child_shelf = nil
        end

        it "sets the relation to nil" do
          parent_shelf.child_shelf.should be_nil
        end

        it "removed the inverse relation" do
          child_shelf.parent_shelf.should be_nil
        end

        it "deletes the child document" do
          child_shelf.should be_destroyed
        end
      end
    end
  end

  describe "#build_#\{name}" do

    context "when providing mass assignment scoping" do

      let(:person) do
        Person.new
      end

      let(:quiz) do
        person.build_quiz(
          { topic: "Testing", name: "Test" }, as: :admin
        )
      end

      it "sets the attributes for the role" do
        quiz.topic.should eq("Testing")
      end

      it "does not set attributes not for the role" do
        quiz.name.should be_nil
      end
    end

    context "when the relation is not cyclic" do

      context "when the parent is a new record" do

        context "when not providing any attributes" do

          context "when building once" do

            let(:person) do
              Person.new
            end

            let!(:name) do
              person.build_name
            end

            it "sets the target of the relation" do
              person.name.should eq(name)
            end

            it "sets the base on the inverse relation" do
              name.namable.should eq(person)
            end

            it "sets no attributes" do
              name.first_name.should be_nil
            end

            it "does not save the target" do
              name.should_not be_persisted
            end
          end

          context "when building twice" do

            let(:person) do
              Person.new
            end

            let!(:name) do
              person.build_name
              person.build_name
            end

            it "sets the target of the relation" do
              person.name.should eq(name)
            end

            it "sets the base on the inverse relation" do
              name.namable.should eq(person)
            end

            it "sets no attributes" do
              name.first_name.should be_nil
            end

            it "does not save the target" do
              name.should_not be_persisted
            end
          end
        end

        context "when passing nil as the attributes" do

          let(:person) do
            Person.new
          end

          let!(:name) do
            person.build_name(nil)
          end

          it "sets the target of the relation" do
            person.name.should eq(name)
          end

          it "sets the base on the inverse relation" do
            name.namable.should eq(person)
          end

          it "sets no attributes" do
            name.first_name.should be_nil
          end

          it "does not save the target" do
            name.should_not be_persisted
          end
        end

        context "when providing attributes" do

          let(:person) do
            Person.new
          end

          let!(:name) do
            person.build_name(first_name: "James")
          end

          it "sets the target of the relation" do
            person.name.should eq(name)
          end

          it "sets the base on the inverse relation" do
            name.namable.should eq(person)
          end

          it "sets the attributes" do
            name.first_name.should eq("James")
          end

          it "does not save the target" do
            name.should_not be_persisted
          end
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let!(:name) do
          person.build_name(first_name: "James")
        end

        it "does not save the target" do
          name.should_not be_persisted
        end
      end
    end

    context "when the relation is cyclic" do

      context "when the parent is a new record" do

        let(:parent_shelf) do
          Shelf.new
        end

        let!(:child_shelf) do
          parent_shelf.build_child_shelf(level: 1)
        end

        it "sets the target of the relation" do
          parent_shelf.child_shelf.should eq(child_shelf)
        end

        it "sets the base on the inverse relation" do
          child_shelf.parent_shelf.should eq(parent_shelf)
        end

        it "sets the attributes" do
          child_shelf.level.should eq(1)
        end

        it "does not save the target" do
          child_shelf.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:parent_shelf) do
          Shelf.create
        end

        let!(:child_shelf) do
          parent_shelf.build_child_shelf(level: 2)
        end

        it "does not save the target" do
          child_shelf.should_not be_persisted
        end
      end
    end
  end

  describe ".builder" do

    let(:base) do
      Person.new
    end

    let(:target) do
      Name.new
    end

    let(:metadata) do
      Person.relations["name"]
    end

    let(:builder_klass) do
      Mongoid::Relations::Builders::Embedded::One
    end

    it "returns the embedded one builder" do
      described_class.builder(base, metadata, target).should be_a(builder_klass)
    end
  end

  describe "#create_#\{name}" do

    context "when providing mass assignment scoping" do

      let(:person) do
        Person.new
      end

      let(:quiz) do
        person.create_quiz(
          { topic: "Testing", name: "Test" }, as: :admin
        )
      end

      it "sets the attributes for the role" do
        quiz.topic.should eq("Testing")
      end

      it "does not set attributes not for the role" do
        quiz.name.should be_nil
      end
    end

    context "when the parent is a new record" do

      context "when not providing any attributes" do

        let(:person) do
          Person.new
        end

        let!(:name) do
          person.create_name
        end

        it "sets the target of the relation" do
          person.name.should eq(name)
        end

        it "sets the base on the inverse relation" do
          name.namable.should eq(person)
        end

        it "sets no attributes" do
          name.first_name.should be_nil
        end

        it "saves the target" do
          name.should be_persisted
        end
      end

      context "when passing nil as the attributes" do

        let(:person) do
          Person.new
        end

        let!(:name) do
          person.create_name(nil)
        end

        it "sets the target of the relation" do
          person.name.should eq(name)
        end

        it "sets the base on the inverse relation" do
          name.namable.should eq(person)
        end

        it "sets no attributes" do
          name.first_name.should be_nil
        end

        it "saves the target" do
          name.should be_persisted
        end
      end

      context "when providing attributes" do

        let(:person) do
          Person.new
        end

        let!(:name) do
          person.create_name(first_name: "James")
        end

        it "sets the target of the relation" do
          person.name.should eq(name)
        end

        it "sets the base on the inverse relation" do
          name.namable.should eq(person)
        end

        it "sets the attributes" do
          name.first_name.should eq("James")
        end

        it "saves the target" do
          name.should be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let!(:name) do
          person.create_name(first_name: "James")
        end

        it "does not save the target" do
          name.should be_persisted
        end
      end
    end
  end

  describe ".embedded?" do

    it "returns true" do
      described_class.should be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns nil" do
      described_class.foreign_key_suffix.should be_nil
    end
  end

  describe ".macro" do

    it "returns embeds_one" do
      described_class.macro.should eq(:embeds_one)
    end
  end

  describe ".nested_builder" do

    let(:nested_builder_klass) do
      Mongoid::Relations::Builders::NestedAttributes::One
    end

    let(:metadata) do
      Person.relations["name"]
    end

    let(:attributes) do
      {}
    end

    it "returns the single nested builder" do
      described_class.nested_builder(metadata, attributes, {}).should
        be_a(nested_builder_klass)
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let!(:name) do
      person.build_name(first_name: "Tony")
    end

    let(:document) do
      person.name
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          document.respond_to?(method).should be_true
        end
      end
    end

    it "responds to persisted?" do
      document.should respond_to(:persisted?)
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should eq(
        [ :autobuild, :as, :cascade_callbacks, :cyclic, :store_as ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should be_true
    end
  end

  context "when the embedded document has an array field" do

    let!(:person) do
      Person.create
    end

    let!(:name) do
      person.create_name(
        first_name: "Syd",
        last_name: "Vicious",
        aliases: nil
      )
    end

    context "when saving the array on a persisted document" do

      let(:from_db) do
        Person.find(person.id).name
      end

      before do
        from_db.aliases = [ "Syd", "Sydney" ]
        from_db.save
      end

      it "sets the values of the array" do
        from_db.aliases.should eq([ "Syd", "Sydney" ])
      end

      it "persists the array" do
        Person.find(person.id).name.aliases.should eq([ "Syd", "Sydney" ])
      end
    end
  end

  context "when embedding a many under a one" do

    let!(:person) do
      Person.create
    end

    before do
      person.create_name
    end

    context "when the documents are reloaded from the database" do

      let(:from_db) do
        Person.first
      end

      context "when adding a new many" do

        let(:name) do
          from_db.name
        end

        let!(:translation) do
          name.translations.new
        end

        context "when saving the root" do

          before do
            from_db.save
          end

          it "persists the new document on the first save" do
            from_db.reload.name.translations.should_not be_empty
          end
        end
      end
    end
  end

  context "when embedding a one under a many" do

    let!(:person) do
      Person.create
    end

    let!(:address_one) do
      person.addresses.create(street: "hobrecht")
    end

    let!(:address_two) do
      person.addresses.create(street: "kreuzberg")
    end

    context "when a parent was removed outside of mongoid" do

      before do
        person.collection.where(_id: person.id).update(
          "$pull" => { "addresses" => { _id: address_one.id }}
        )
      end

      it "reloads the correct number" do
        person.reload.addresses.count.should eq(1)
      end

      context "when adding a child" do

        let(:code) do
          Code.new
        end

        before do
          address_two.code = code
        end

        it "reloads the correct number" do
          person.reload.addresses.count.should eq(1)
        end
      end
    end
  end

  context "when embedded documents are stored without ids" do

    let!(:band) do
      Band.create(name: "Moderat")
    end

    before do
      band.collection.
        find(_id: band.id).
        update("$set" => { label: { name: "Mute" }})
    end

    context "when loading the documents" do

      before do
        band.reload
      end

      let(:label) do
        band.label
      end

      it "creates proper documents from the db" do
        label.name.should eq("Mute")
      end

      it "assigns ids to the documents" do
        label.id.should_not be_nil
      end

      context "when subsequently updating the documents" do

        before do
          label.update_attribute(:name, "Interscope")
        end

        it "updates the document" do
          label.name.should eq("Interscope")
        end

        it "persists the change" do
          label.reload.name.should eq("Interscope")
        end
      end
    end
  end
end
