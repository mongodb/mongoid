# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe "#discriminator_key" do 

  context "when the discriminator key is not set on a class" do
    let(:piano) do 
      Piano.new
    end

    let(:guitar) do 
      Guitar.new
    end  
    
    it "sets the child discriminator key to _type: Piano" do
      expect(piano._type).to eq("Piano")
    end

    it "sets the child discriminator key to _type: Guitar" do
      expect(guitar._type).to eq("Guitar")
    end
  end
  
  context "when the discriminator key is changed in the parent" do
    before do
      Instrument.discriminator_key = "hello2"
    end

    after do
      Instrument.discriminator_key = nil
    end

    let(:piano) do 
      Piano.new
    end

    let(:guitar) do 
      Guitar.new
    end

    it "changes in the child class: Piano" do
      expect(piano.hello2).to eq("Piano")
    end

    it "changes in the child class: Guitar" do
      expect(guitar.hello2).to eq("Guitar")
    end
  end

  context "when the discriminator key is changed at the base level" do
    context "after class creation" do
      before do
        class GlobalIntDiscriminatorParent
          include Mongoid::Document
        end
        
        class GlobalIntDiscriminatorChild < GlobalIntDiscriminatorParent
        end
        
        Mongoid.discriminator_key = "test"
      end

      after do
        Mongoid.discriminator_key = "_type"
      end

      let(:child) do 
        GlobalIntDiscriminatorChild.new
      end

      it "has a discriminator key _type" do 
        expect(child._type).to eq("GlobalIntDiscriminatorChild")
      end

      it "does not have the new global value as a field" do
        expect(defined?(child.test)).to be nil
      end
    end

    context "before class creation" do
      before do
        Mongoid.discriminator_key = "test"

        class PreGlobalIntDiscriminatorParent
          include Mongoid::Document
        end
        
        class PreGlobalIntDiscriminatorChild < PreGlobalIntDiscriminatorParent
        end
      end

      after do
        Mongoid.discriminator_key = "_type"
      end

      let(:child) do 
        PreGlobalIntDiscriminatorChild.new
      end

      it "creates a field with new discriminator key" do 
        expect(child.test).to eq("PreGlobalIntDiscriminatorChild")
      end
      
      it "does not have the default value as a field" do
        expect(defined?(child._type)).to be nil
      end
    end
  end

  context "when the discriminator key is changed in the parent" do 
    context "after child class creation" do
      before do
        class LocalIntDiscriminatorParent
          include Mongoid::Document
        end

        class LocalIntDiscriminatorChild < LocalIntDiscriminatorParent
        end

        LocalIntDiscriminatorParent.discriminator_key = "test2"
      end

      let(:child) do 
        LocalIntDiscriminatorChild.new
      end

      it "still has _type field in the child" do 
        expect(child._type).to include("LocalIntDiscriminatorChild")
      end

      it "has the new field in the child" do 
        expect(child.test2).to include("LocalIntDiscriminatorChild")
      end
    end

    context "before child class creation" do
      before do
        class PreLocalIntDiscriminatorParent
          include Mongoid::Document
          self.discriminator_key = "test2"
        end

        class PreLocalIntDiscriminatorChild < PreLocalIntDiscriminatorParent
        end
      end

      let(:child) do 
        PreLocalIntDiscriminatorChild.new
      end

      it "creates a new field in the child" do 
        expect(child.test2).to include("PreLocalIntDiscriminatorChild")
      end

      it "does not have the default value as a field" do
        expect(defined?(child._type)).to be nil
      end
    end
  end
end
