# frozen_string_literal: true
# encoding: utf-8

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

      it "includes embedded documents multiple levels deep" do
        expect(person._children).to include(location)
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
      before do
        Mongoid.discriminator_key = "hello"
      end

      after do
        Mongoid.discriminator_key = "_type"
      end

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
          before do
            Mongoid.discriminator_key = "test"

            class PreGlobalDiscriminatorParent
              include Mongoid::Document
            end
            
            class PreGlobalDiscriminatorChild < PreGlobalDiscriminatorParent
            end
          end
    
          after do
            Mongoid.discriminator_key = "_type"
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
          before do
            Mongoid.discriminator_key = :test

            class PreGlobalSymDiscriminatorParent
              include Mongoid::Document
            end
            
            class PreGlobalSymDiscriminatorChild < PreGlobalSymDiscriminatorParent
            end
          end
    
          after do
            Mongoid.discriminator_key = "_type"
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
  end
end
