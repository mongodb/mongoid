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
        it "equals _type" do
          expect(Instrument.discriminator_key).to eq("_type")
        end
  
        it "child's discriminator key equals _type: Guitar" do
          expect(Guitar.fields.keys).to include("_type")
        end

        it "child's discriminator key equals _type: Piano" do
          expect(Piano.fields.keys).to include("_type")
        end
      end
  
      context "when the discriminator key is changed at the base level" do
        context "after class creation" do
          before do
            class GlobalDiscriminiatorParent
              include Mongoid::Document
            end
            
            class GlobalDiscriminiatorChild < GlobalDiscriminiatorParent
            end
            
            Mongoid.discriminator_key = "test"
          end
    
          after do
            Mongoid.discriminator_key = "_type"
          end
    
          it "parent uses original global value" do 
            expect(GlobalDiscriminiatorParent.fields.keys).to include("_type")
          end

          it "child uses original global value" do 
            expect(GlobalDiscriminiatorChild.fields.keys).to include("_type")
          end

          it "parent does not use global value" do 
            expect(GlobalDiscriminiatorParent.fields.keys).to_not include("test")
          end

          it "child does not use global value" do 
            expect(GlobalDiscriminiatorChild.fields.keys).to_not include("test")
          end
          
        end

        context "before class creation" do
          before do
            Mongoid.discriminator_key = "test"

            class PreGlobalDiscriminiatorParent
              include Mongoid::Document
            end
            
            class PreGlobalDiscriminiatorChild < PreGlobalDiscriminiatorParent
            end
            
            Mongoid.discriminator_key = "test"
          end
    
          after do
            Mongoid.discriminator_key = "_type"
          end

          it "parent has new discriminator key" do 
            expect(PreGlobalDiscriminiatorParent.fields.keys).to include("test")
          end

          it "child has new discriminator key" do 
            expect(PreGlobalDiscriminiatorChild.fields.keys).to include("test")
          end

          it "parent does not have original discriminator key" do 
            expect(PreGlobalDiscriminiatorParent.fields.keys).to_not include("_type")
          end

          it "child does not have original discriminator key" do 
            expect(PreGlobalDiscriminiatorChild.fields.keys).to_not include("_type")
          end
        end
      end
  
      context "when the discriminator key is changed in the parent" do 
        context "after child class creation" do
          before do
            class LocalDiscriminiatorParent
              include Mongoid::Document
            end

            class LocalDiscriminiatorChild < LocalDiscriminiatorParent
            end

            LocalDiscriminiatorParent.discriminator_key = "test2"
          end
    
          after do 
            LocalDiscriminiatorParent.discriminator_key = "_type"
          end
    
          it "a new field is added" do 
            expect(LocalDiscriminiatorParent.fields.keys).to include("test2")
            expect(LocalDiscriminiatorParent.fields.keys).to include("_type")
          end

          it "still has _type field" do 
            expect(LocalDiscriminiatorChild.fields.keys).to include("_type")
          end

          it "new fields are added in the child classes" do 
            expect(LocalDiscriminiatorChild.fields.keys).to include("test2")
          end
        end

        context "before child class creation" do
          before do
            class PreLocalDiscriminiatorParent
              include Mongoid::Document
              self.discriminator_key = "test2"
            end

            class PreLocalDiscriminiatorChild < PreLocalDiscriminiatorParent
            end
          end
    
          after do 
            PreLocalDiscriminiatorParent.discriminator_key = "_type"
          end
    
          it "_type field is not added" do 
            expect(PreLocalDiscriminiatorParent.fields.keys).to_not include("_type")
            expect(PreLocalDiscriminiatorParent.fields.keys).to_not include("_type")
          end

          it "new field added in the child class" do 
            expect(PreLocalDiscriminiatorChild.fields.keys).to include("test2")
          end
        end

        context "when there's no child class" do
          before do
            class LocalDiscriminiatorNonParent
              include Mongoid::Document
              self.discriminator_key = "test2"
            end
          end
    
          after do 
            LocalDiscriminiatorNonParent.discriminator_key = "_type"
          end
    
          it "_type field is not added" do 
            expect(LocalDiscriminiatorNonParent.fields.keys).to_not include("_type")
          end

          it "new field not added" do 
            expect(LocalDiscriminiatorNonParent.fields.keys).to_not include("test2")
          end
        end
      end
    end
  end
end
