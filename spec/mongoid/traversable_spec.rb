# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Traversable do

  describe "#_children" do

    let(:person) do
      Person.new(title: "King")
    end

    context "with one level of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      before do
        person.name = name
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._children).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._children).to include(address)
      end
    end

    context "with multiple levels of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      let(:location) do
        Location.new(name: "Work")
      end

      before do
        person.name = name
        address.locations << location
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._children).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._children).to include(address)
      end

      it "does not include embedded documents multiple levels deep" do
        expect(person._children).not_to include(location)
      end
    end
  end

  describe "#_descendants" do

    let(:person) do
      Person.new(title: "King")
    end

    context "with one level of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      before do
        person.name = name
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._descendants).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._descendants).to include(address)
      end
    end

    context "with multiple levels of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      let(:location) do
        Location.new(name: "Work")
      end

      before do
        person.name = name
        address.locations << location
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._descendants).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._descendants).to include(address)
      end

      it "includes embedded documents multiple levels deep" do
        expect(person._descendants).to include(location)
      end
    end
  end

  describe ".hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        expect(Circle.hereditary?).to be true
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        expect(Shape.hereditary?).to be false
      end
    end
  end

  describe "#hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        expect(Circle.new).to be_hereditary
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        expect(Shape.new).to_not be_hereditary
      end
    end
  end

  describe "#inherited" do

    it "duplicates the localized fields" do
      expect(Actress.localized_fields).to_not equal(Actor.localized_fields)
    end
  end

  describe "#parentize" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    it "sets the parent document" do
      expect(address._parent).to eq(person)
    end
  end

  describe "#remove_child" do

    let(:person) do
      Person.new
    end

    context "when child is an embeds one" do

      let!(:name) do
        person.build_name(first_name: "James")
      end

      before do
        person.remove_child(name)
      end

      it "removes the relation instance" do
        expect(person.name).to be_nil
      end
    end

    context "when child is an embeds many" do

      let!(:address) do
        person.addresses.build(street: "Upper St")
      end

      before do
        person.remove_child(address)
      end

      it "removes the document from the relation target" do
        expect(person.addresses).to be_empty
      end
    end
  end

  describe "#_root" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    context "when the document is not the root" do

      it "returns the root" do
        expect(address._root).to eq(person)
      end
    end

    context "when the document is the root" do

      it "returns self" do
        expect(person._root).to eq(person)
      end
    end
  end

  describe "#_root?" do

    context "when the document can be the root" do

      context "when the document is not embedded" do

        let(:band) do
          Band.new
        end

        it "returns true" do
          expect(band).to be__root
        end
      end

      context "when the document is embedded" do

        let(:root_role) do
          Role.new
        end

        context "when the document is root in a cyclic relation" do

          it "returns true" do
            expect(root_role).to be__root
          end
        end

        context "when document is embedded in a cyclic relation" do

          let(:child_role) do
            root_role.child_roles.build
          end

          it "returns false" do
            expect(child_role).to_not be__root
          end
        end
      end
    end

    context "when the document is embedded and not cyclic" do

      let(:person) do
        Person.new
      end

      let(:address) do
        person.addresses.build
      end

      it "returns false" do
        expect(address).to_not be__root
      end
    end
  end

  describe "#discriminator_key" do

    context "when the discriminator key is not set on a class" do
      it "sets the global discriminator key to _type" do
        expect(Mongoid.discriminator_key).to eq("_type")
      end

      it "sets the parent discriminator key to _type" do
        expect(Instrument.discriminator_key).to eq("_type")
      end

      it "sets the child discriminator key to _type: Piano" do
        expect(Piano.discriminator_key).to eq("_type")
      end

      it "sets the child discriminator key to _type: Guitar" do
        expect(Guitar.discriminator_key).to eq("_type")
      end
    end

    context "when the discriminator key is changed at the global level" do
      config_override :discriminator_key, 'hello'

      it "sets the correct value globally" do
        expect(Mongoid.discriminator_key).to eq("hello")
      end

      it "is changed in the parent" do
        expect(Instrument.discriminator_key).to eq("hello")
      end

      it "is changed in the child: Piano" do
        expect(Piano.discriminator_key).to eq("hello")
      end

      it "is changed in the child: Guitar" do
        expect(Guitar.discriminator_key).to eq("hello")
      end
    end

    context "when the discriminator key is changed in the parent" do
      before do
        Instrument.discriminator_key = "hello2"
      end

      after do
        Instrument.discriminator_key = nil
      end

      it "doesn't change the global setting" do
        expect(Mongoid.discriminator_key).to eq("_type")
      end

      it "changes in the parent" do
        expect(Instrument.discriminator_key).to eq("hello2")
      end

      it "changes in the child class: Piano" do
        expect(Piano.discriminator_key).to eq("hello2")
      end

      it "changes in the child class: Guitar" do
        expect(Guitar.discriminator_key).to eq("hello2")
      end

      context 'when discriminator key is set to nil in parent' do
        before do
          Instrument.discriminator_key = nil
        end

        it "doesn't change the global setting" do
          expect(Mongoid.discriminator_key).to eq("_type")
        end

        it 'uses global setting' do
          expect(Instrument.discriminator_key).to eq("_type")
        end

        it "changes in the child class: Piano" do
          expect(Piano.discriminator_key).to eq("_type")
        end

        it "changes in the child class: Guitar" do
          expect(Guitar.discriminator_key).to eq("_type")
        end
      end

      context "when resetting the discriminator key after nil" do
        before do
          Instrument.discriminator_key = nil
          Instrument.discriminator_key = "hello4"
        end

        it "doesn't change the global setting" do
          expect(Mongoid.discriminator_key).to eq("_type")
        end

        it 'has the correct value' do
          expect(Instrument.discriminator_key).to eq("hello4")
        end

        it "changes in the child class: Piano" do
          expect(Piano.discriminator_key).to eq("hello4")
        end

        it "changes in the child class: Guitar" do
          expect(Guitar.discriminator_key).to eq("hello4")
        end
      end
    end

    context "when the discriminator key is changed in the child" do
      let(:set_discriminator_key) do
        Guitar.discriminator_key = "hello3"
      end

      before :each do
        begin
          set_discriminator_key
        rescue
        end
      end

      it "raises an error" do
        expect do
          set_discriminator_key
        end.to raise_error(Mongoid::Errors::InvalidDiscriminatorKeyTarget)
      end

      it "doesn't change in that class" do
        expect(Guitar.discriminator_key).to eq("_type")
      end

      it "doesn't change the global setting" do
        expect(Mongoid.discriminator_key).to eq("_type")
      end

      it "doesn't change in the sibling" do
        expect(Piano.discriminator_key).to eq("_type")
      end

      it "doesn't change in the parent" do
        expect(Instrument.discriminator_key).to eq("_type")
      end
    end

    context "when discriminator key is called on an instance" do

      let(:guitar) do
        Guitar.new
      end

      it "raises an error on setter" do
        expect do
          guitar.discriminator_key = "hello3"
        end.to raise_error(NoMethodError)
      end

      it "raises an error on getter" do
        expect do
          guitar.discriminator_key
        end.to raise_error(NoMethodError)
      end
    end

    context ".fields" do
      context "when the discriminator key is not changed" do
        it "creates a _type field in the parent" do
          expect(Instrument.fields.keys).to include("_type")
        end

        it "creates a _type field in the child: Guitar" do
          expect(Guitar.fields.keys).to include("_type")
        end

        it "creates a _type field in the child: Piano" do
          expect(Piano.fields.keys).to include("_type")
        end
      end

      context "when the discriminator key is changed at the base level" do
        context "after class creation" do
          before do
            class GlobalDiscriminatorParent
              include Mongoid::Document
            end

            class GlobalDiscriminatorChild < GlobalDiscriminatorParent
            end

            Mongoid.discriminator_key = "test"
          end

          after do
            Mongoid.discriminator_key = "_type"
          end

          it "creates a field with the old global value in the parent" do
            expect(GlobalDiscriminatorParent.fields.keys).to include("_type")
          end

          it "creates a field with the old global value in the child" do
            expect(GlobalDiscriminatorChild.fields.keys).to include("_type")
          end

          it "does not have the new global value in the parent" do
            expect(GlobalDiscriminatorParent.fields.keys).to_not include("test")
          end

          it "does not have the new global value in the child" do
            expect(GlobalDiscriminatorChild.fields.keys).to_not include("test")
          end

        end

        context "before class creation" do
          config_override :discriminator_key, "test"

          before do
            class PreGlobalDiscriminatorParent
              include Mongoid::Document
            end

            class PreGlobalDiscriminatorChild < PreGlobalDiscriminatorParent
            end
          end

          it "creates a field with new discriminator key in the parent" do
            expect(PreGlobalDiscriminatorParent.fields.keys).to include("test")
          end

          it "creates a field with new discriminator key in the child" do
            expect(PreGlobalDiscriminatorChild.fields.keys).to include("test")
          end

          it "does not have the original discriminator key in the parent" do
            expect(PreGlobalDiscriminatorParent.fields.keys).to_not include("_type")
          end

          it "does not have the original discriminator key in the child" do
            expect(PreGlobalDiscriminatorChild.fields.keys).to_not include("_type")
          end
        end
      end

      context "when the discriminator key is changed in the parent" do
        context "after child class creation" do
          before do
            class LocalDiscriminatorParent
              include Mongoid::Document
            end

            class LocalDiscriminatorChild < LocalDiscriminatorParent
            end

            LocalDiscriminatorParent.discriminator_key = "test2"
          end

          it "creates a new field in the parent" do
            expect(LocalDiscriminatorParent.fields.keys).to include("test2")
          end

          it "does not remove the original field in the parent" do
            expect(LocalDiscriminatorParent.fields.keys).to include("_type")
          end

          it "still has _type field in the child" do
            expect(LocalDiscriminatorChild.fields.keys).to include("_type")
          end

          it "has the new field in the child" do
            expect(LocalDiscriminatorChild.fields.keys).to include("test2")
          end
        end

        context "before child class creation" do
          before do
            class PreLocalDiscriminatorParent
              include Mongoid::Document
              self.discriminator_key = "test2"
            end

            class PreLocalDiscriminatorChild < PreLocalDiscriminatorParent
            end
          end

          it "creates a new field in the parent" do
            expect(PreLocalDiscriminatorParent.fields.keys).to include("test2")
          end

          it "does not create the _type field in the parent" do
            expect(PreLocalDiscriminatorParent.fields.keys).to_not include("_type")
          end

          it "creates a new field in the child" do
            expect(PreLocalDiscriminatorChild.fields.keys).to include("test2")
          end
        end

        context "when there's no child class" do
          before do
            class LocalDiscriminatorNonParent
              include Mongoid::Document
              self.discriminator_key = "test2"
            end
          end

          it "does not create a _type field" do
            expect(LocalDiscriminatorNonParent.fields.keys).to_not include("_type")
          end

          it "does not create a new field" do
            expect(LocalDiscriminatorNonParent.fields.keys).to_not include("test2")
          end
        end
      end
    end

    context "when setting the discriminator key as a symbol" do
      context "when the discriminator key is changed at the base level" do
        context "after class creation" do
          before do
            class GlobalSymDiscriminatorParent
              include Mongoid::Document
            end

            class GlobalSymDiscriminatorChild < GlobalSymDiscriminatorParent
            end

            Mongoid.discriminator_key = :test
          end

          after do
            Mongoid.discriminator_key = "_type"
          end

          it "gets converted to a string in the parent" do
            expect(GlobalSymDiscriminatorParent.fields.keys).to_not include("test")
          end

          it "gets converted to a string in the child" do
            expect(GlobalSymDiscriminatorChild.fields.keys).to_not include("test")
          end

          it "is a string globally" do
            expect(Mongoid.discriminator_key).to eq("test")
          end

          it "is a string in the parent" do
            expect(GlobalSymDiscriminatorParent.discriminator_key).to eq("test")
          end

          it "is a string in the child" do
            expect(GlobalSymDiscriminatorChild.discriminator_key).to eq("test")
          end
        end

        context "before class creation" do
          config_override :discriminator_key, :test

          before do
            class PreGlobalSymDiscriminatorParent
              include Mongoid::Document
            end

            class PreGlobalSymDiscriminatorChild < PreGlobalSymDiscriminatorParent
            end
          end

          it "creates a field with new discriminator key as a string in the parent" do
            expect(PreGlobalSymDiscriminatorParent.fields.keys).to include("test")
          end

          it "creates a field with new discriminator key as a string in the child" do
            expect(PreGlobalSymDiscriminatorChild.fields.keys).to include("test")
          end

          it "is a string globally" do
            expect(Mongoid.discriminator_key).to eq("test")
          end

          it "is a string in the parent" do
            expect(PreGlobalSymDiscriminatorParent.discriminator_key).to eq("test")
          end

          it "is a string in the child" do
            expect(PreGlobalSymDiscriminatorChild.discriminator_key).to eq("test")
          end
        end
      end

      context "when the discriminator key is changed in the parent" do
        context "after child class creation" do
          before do
            class LocalSymDiscriminatorParent
              include Mongoid::Document
            end

            class LocalSymDiscriminatorChild < LocalSymDiscriminatorParent
            end

            LocalSymDiscriminatorParent.discriminator_key = :test2
          end

          it "creates a new field of type string in the parent" do
            expect(LocalSymDiscriminatorParent.fields.keys).to include("test2")
          end

          it "creates a new field of type string in the child" do
            expect(LocalSymDiscriminatorChild.fields.keys).to include("test2")
          end

          it "is a string in the parent" do
            expect(LocalSymDiscriminatorParent.discriminator_key).to eq("test2")
          end

          it "is a string in the child" do
            expect(LocalSymDiscriminatorChild.discriminator_key).to eq("test2")
          end
        end

        context "before child class creation" do
          before do
            class PreLocalSymDiscriminatorParent
              include Mongoid::Document
              self.discriminator_key = :test2
            end

            class PreLocalSymDiscriminatorChild < PreLocalSymDiscriminatorParent
            end
          end

          it "creates a new field of type string in the parent" do
            expect(PreLocalSymDiscriminatorParent.fields.keys).to include("test2")
          end

          it "creates a new field of type string in the child" do
            expect(PreLocalSymDiscriminatorChild.fields.keys).to include("test2")
          end

          it "is a string in the parent" do
            expect(PreLocalSymDiscriminatorParent.discriminator_key).to eq("test2")
          end

          it "is a string in the child" do
            expect(PreLocalSymDiscriminatorChild.discriminator_key).to eq("test2")
          end
        end
      end
    end

    context "when setting the discriminator key as" do
      context "a number" do
        before do
          Instrument.discriminator_key = 3
        end

        after do
          Instrument.discriminator_key = nil
        end

        it "gets converted to a string" do
          expect(Instrument.fields.keys).to include("3")
        end

        it "is a string in the parent" do
          expect(Instrument.discriminator_key).to eq("3")
        end

        it "is a string in the child: Guitar" do
          expect(Guitar.discriminator_key).to eq("3")
        end

        it "is a string in the child: Piano" do
          expect(Piano.discriminator_key).to eq("3")
        end
      end

      context "a boolean" do
        before do
          Instrument.discriminator_key = true
        end

        after do
          Instrument.discriminator_key = nil
        end

        it "gets converted to a string" do
          expect(Instrument.fields.keys).to include("true")
        end

        it "is a string in the parent" do
          expect(Instrument.discriminator_key).to eq("true")
        end

        it "is a string in the child: Guitar" do
          expect(Guitar.discriminator_key).to eq("true")
        end

        it "is a string in the child: Piano" do
          expect(Piano.discriminator_key).to eq("true")
        end
      end
    end

    context "when setting a field equal to discriminator key and duplicate_fields_exception is true" do
      config_override :duplicate_fields_exception, true

      before do

        class DuplicateDiscriminatorKeyParent
          include Mongoid::Document
          field :dkey, type: String
        end

        class DuplicateDiscriminatorKeyChild < DuplicateDiscriminatorKeyParent
        end
      end

      it "does not raise an error" do
        expect do
          DuplicateDiscriminatorKeyParent.discriminator_key = "dkey"
        end.to_not raise_error
      end
    end

    context "when the discriminator key conflicts with mongoid's internals" do

      after do
        Person.discriminator_key = nil
      end

      [:_association, :invalid].each do |meth|
        context "when the field is named #{meth}" do

          it "raises an error" do
            expect {
              Person.discriminator_key = meth
            }.to raise_error(Mongoid::Errors::InvalidField)
          end
        end
      end
    end

    context "when setting a field equal to global discriminator key and duplicate_fields_exception is true" do
      config_override :duplicate_fields_exception, true
      config_override :discriminator_key, "dkey"

      before do

        class GlobalDuplicateDiscriminatorKeyParent
          include Mongoid::Document
        end

        class GlobalDuplicateDiscriminatorKeyChild < GlobalDuplicateDiscriminatorKeyParent
        end
      end

      it "raises an error" do
        expect do
          GlobalDuplicateDiscriminatorKeyParent.class_eval do
            field("dkey")
          end
        end.to raise_error(Mongoid::Errors::InvalidField)
      end
    end

    context "when the global discriminator key conflicts with mongoid's internals" do
      # This is not an override, it is meant to restore the original value
      # after the test only.
      config_override :discriminator_key, '_type'

      [:_association, :invalid].each do |meth|
        context "when the field is named #{meth}" do

          it "raises an error" do
            expect do
              Mongoid.discriminator_key = meth
            end.to raise_error(Mongoid::Errors::InvalidField)
          end
        end
      end
    end
  end

  describe "#discriminator_value" do

    context "when the discriminator value is not set" do

      it "has the correct discriminator_value" do
        expect(Guitar.discriminator_value).to eq("Guitar")
      end

      it "has the correct discriminator_value" do
        expect(Piano.discriminator_value).to eq("Piano")
      end

      it "has the correct discriminator_value" do
        expect(Instrument.discriminator_value).to eq("Instrument")
      end
    end


    context "when the discriminator value is set on the child class" do
      before do
        Guitar.discriminator_value = "some string instrument"
      end

      after do
        Guitar.discriminator_value = nil
      end

      it "has the correct discriminator_value" do
        expect(Guitar.discriminator_value).to eq("some string instrument")
      end

      it "does not change the sibling's discriminator value" do
        expect(Piano.discriminator_value).to eq("Piano")
      end

      it "does not change the parent's discriminator value" do
        expect(Instrument.discriminator_value).to eq("Instrument")
      end
    end

    context "when the discriminator value is set on the parent" do
      before do
        Instrument.discriminator_value = "musical thingy"
      end

      after do
        Instrument.discriminator_value = nil
      end

      it "is changed in the parent" do
        expect(Instrument.discriminator_value).to eq("musical thingy")
      end

      it "is not changed in the child: Guitar" do
        expect(Guitar.discriminator_value).to eq("Guitar")
      end

      it "is not changed in the child: Piano" do
        expect(Piano.discriminator_value).to eq("Piano")
      end
    end

    context "when setting the discriminator value to nil" do
      before do
        Guitar.discriminator_value = "some string instrument"
        Guitar.discriminator_value = nil
      end

      it "reverts back to default" do
        expect(Guitar.discriminator_value).to eq("Guitar")
      end
    end

    context "when setting discriminator value on parent that is also a child" do
      before do
        Browser.discriminator_value = "something"
      end

      after do
        Browser.discriminator_value = nil
      end

      it "has the correct value in the parent" do
        expect(Browser.discriminator_value).to eq("something")
      end

      it "doesn't set the grandchild's discriminator value" do
        expect(Firefox.discriminator_value).to eq("Firefox")
      end
    end

    describe ".fields" do

      let(:guitar) do
        Guitar.new
      end

      let(:piano) do
        Piano.new
      end

      let(:instrument) do
        Instrument.new
      end

      context "when the discriminator value is not set" do
        it "has the correct discriminator_value" do
          expect(guitar._type).to eq("Guitar")
        end

        it "has the correct discriminator_value" do
          expect(piano._type).to eq("Piano")
        end

        it "has the correct discriminator_value" do
          expect(instrument._type).to eq("Instrument")
        end
      end

      context "when the discriminator value is set on the child class" do
        before do
          Guitar.discriminator_value = "some string instrument"
        end

        after do
          Guitar.discriminator_value = nil
        end

        it "has the correct discriminator_value" do
          expect(guitar._type).to eq("some string instrument")
        end

        it "does not change the sibling's discriminator value" do
          expect(piano._type).to eq("Piano")
        end

        it "does not change the parent's discriminator value" do
          expect(instrument._type).to eq("Instrument")
        end

        it "retrieves the correct discriminator_mapping from the parent" do
          expect(
            Instrument.get_discriminator_mapping("some string instrument")
          ).to eq(Guitar)
        end

        it "retrieves the correct discriminator_mapping from the child: Guitar" do
          expect(
            Guitar.get_discriminator_mapping("some string instrument")
          ).to eq(Guitar)
        end

        it "is not retrieved from the sibling" do
          expect(
            Piano.get_discriminator_mapping("some string instrument")
          ).to be nil
        end
      end

      context "when the discriminator value is set on the parent" do
        before do
          Instrument.discriminator_value = "musical thingy"
        end

        after do
          Instrument.discriminator_value = nil
        end

        it "is changed in the parent" do
          expect(instrument._type).to eq("musical thingy")
        end

        it "is not changed in the child: Guitar" do
          expect(guitar._type).to eq("Guitar")
        end

        it "is not changed in the child: Piano" do
          expect(piano._type).to eq("Piano")
        end

        it "retrieves the correct discriminator_mapping from the parent" do
          expect(
            Instrument.get_discriminator_mapping("musical thingy")
          ).to eq(Instrument)
        end

        it "is not retrieved from the child: Guitar" do
          expect(
            Guitar.get_discriminator_mapping("musical thingy")
          ).to be nil
        end

        it "is not retrieved from the child: Piano" do
          expect(
            Piano.get_discriminator_mapping("musical thingy")
          ).to be nil
        end
      end

      context "when setting the discriminator value to nil" do
        before do
          Guitar.discriminator_value = "some string instrument"
          Guitar.discriminator_value = nil
        end

        it "reverts back to default" do
          expect(guitar._type).to eq("Guitar")
        end

        it "retrieves the correct discriminator_mapping" do
          expect(
            Instrument.get_discriminator_mapping("Guitar")
          ).to eq(Guitar)
        end

        it "retrieves the old discriminator_mapping" do
          expect(
            Instrument.get_discriminator_mapping("some string instrument")
          ).to eq(Guitar)
        end
      end

      context "when setting discriminator value on parent that is also a child" do
        before do
          Browser.discriminator_value = "something"
        end

        after do
          Browser.discriminator_value = nil
        end

        let(:browser) do
          Browser.new
        end

        let(:firefox) do
          Firefox.new
        end

        it "has the correct value in the parent" do
          expect(browser._type).to eq("something")
        end

        it "doesn't set the grandchild's discriminator value" do
          expect(firefox._type).to eq("Firefox")
        end

        it "retrieves the correct discriminator_mapping from the grandparent" do
          expect(
            Canvas.get_discriminator_mapping("something")
          ).to eq(Browser)
        end

        it "retrieves the correct discriminator_mapping from the parent" do
          expect(
            Browser.get_discriminator_mapping("something")
          ).to eq(Browser)
        end

        it "is not retrieved from the grandchild" do
          expect(
            Firefox.get_discriminator_mapping("something")
          ).to be nil
        end
      end

      context "when changing the discriminator key" do
        before do
          Instrument.discriminator_key = "dkey"
          Guitar.discriminator_value = "string instrument"
        end

        after do
          Instrument.discriminator_key = nil
          Guitar.discriminator_value = nil
        end

        let(:guitar) do
          Guitar.new
        end

        it "has the correct discriminator_value for the new discriminator_key" do
          expect(guitar.dkey).to eq("string instrument")
        end

        it "has the correct discriminator_value for the old discriminator_key" do
          expect(guitar._type).to eq("string instrument")
        end

        it "retrieves the correct discriminator_mapping from the parent" do
          expect(
            Instrument.get_discriminator_mapping("string instrument")
          ).to eq(Guitar)
        end

        it "retrieves the correct discriminator_mapping from the child: Guitar" do
          expect(
            Guitar.get_discriminator_mapping("string instrument")
          ).to eq(Guitar)
        end

        it "is not retrieved from the sibling" do
          expect(
            Piano.get_discriminator_mapping("string instrument")
          ).to be nil
        end
      end

      context "when the discriminator value is set twice" do
        before do
          Instrument.discriminator_value = "something"
          Instrument.discriminator_value = "musical thingy"
        end

        after do
          Instrument.discriminator_value = nil
        end

        it "is changed in the parent" do
          expect(instrument._type).to eq("musical thingy")
        end

        it "is not changed in the child: Guitar" do
          expect(guitar._type).to eq("Guitar")
        end

        it "is not changed in the child: Piano" do
          expect(piano._type).to eq("Piano")
        end

        it "retrieves the correct discriminator_mapping from the parent" do
          expect(
            Instrument.get_discriminator_mapping("musical thingy")
          ).to eq(Instrument)
        end

        it "is not retrieved from the child: Guitar" do
          expect(
            Guitar.get_discriminator_mapping("musical thingy")
          ).to be nil
        end

        it "ris not retrieved from the child: Piano" do
          expect(
            Piano.get_discriminator_mapping("musical thingy")
          ).to be nil
        end
      end
    end

    context "when using the Class.new syntax" do
      context "when assigning to a constant" do
        before :all do
          NewClassPerson = Class.new(Person)
          NewClassPerson2 = Class.new(NewClassPerson)
        end

        it "has the correct discriminator_value when doing one Class.new" do
          expect(NewClassPerson.discriminator_value).to eq('NewClassPerson')
        end

        it "has the correct discriminator_value when doing two Class.new's" do
          expect(NewClassPerson2.discriminator_value).to eq('NewClassPerson2')
        end
      end
    end
  end

  describe "#discriminator_mapping" do
    context "when not changing discriminator_mappings" do
      it "has the class name as the value: Instrument" do
        expect(
          Instrument.get_discriminator_mapping("Instrument")
        ).to eq(Instrument)
      end

      it "has the class name as the value: Guitar" do
        expect(
          Guitar.get_discriminator_mapping("Guitar")
        ).to eq(Guitar)
      end

      it "has the class name as the value: Piano" do
        expect(
          Piano.get_discriminator_mapping("Piano")
        ).to eq(Piano)
      end
    end

    context "when adding to the parent" do
      before do
        Instrument.add_discriminator_mapping("some_dmap")
      end

      after do
        Instrument.add_discriminator_mapping("Instrument")
      end

      it "can be retrieved from the parent" do
        expect(
          Instrument.get_discriminator_mapping("some_dmap")
        ).to eq(Instrument)
      end

      it "can be retrieved from the child: Guitar" do
        expect(
          Guitar.get_discriminator_mapping("some_dmap")
        ).to be nil
      end

      it "can be retrieved from the child: Piano" do
        expect(
          Piano.get_discriminator_mapping("some_dmap")
        ).to be nil
      end
    end

    context "when adding to the child" do
      before do
        Guitar.add_discriminator_mapping("something")
      end

      after do
        Guitar.add_discriminator_mapping("Guitar")
      end

      it "can be retrieved from the parent" do
        expect(
          Instrument.get_discriminator_mapping("something")
        ).to eq(Guitar)
      end

      it "can be retrieved from the child: Guitar" do
        expect(
          Guitar.get_discriminator_mapping("something")
        ).to eq(Guitar)
      end

      it "is not retrieved from the sibling" do
        expect(
          Piano.get_discriminator_mapping("something")
        ).to be nil
      end
    end

    context "when adding to the same class twice" do
      before do
        Guitar.add_discriminator_mapping("something")
        Guitar.add_discriminator_mapping("something else")
      end

      after do
        Guitar.add_discriminator_mapping("Guitar")
      end

      it "retrieves the new value from the parent" do
        expect(
          Instrument.get_discriminator_mapping("something else")
        ).to eq(Guitar)
      end

      it "retrieves the new value from the child: Guitar" do
        expect(
          Guitar.get_discriminator_mapping("something else")
        ).to eq(Guitar)
      end

      it "is not retrieved from the sibling" do
        expect(
          Piano.get_discriminator_mapping("something else")
        ).to be nil
      end

      it "retrieves the old value from the parent" do
        expect(
          Instrument.get_discriminator_mapping("something")
        ).to eq(Guitar)
      end

      it "retrieves the old value from the child: Guitar" do
        expect(
          Guitar.get_discriminator_mapping("something")
        ).to eq(Guitar)
      end

      it "does not retrieves the old value from the sibling" do
        expect(
          Piano.get_discriminator_mapping("something")
        ).to be nil
      end
    end
  end
end
