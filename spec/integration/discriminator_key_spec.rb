# frozen_string_literal: true

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
        Object.send(:remove_const, :GlobalIntDiscriminatorParent)
        Object.send(:remove_const, :GlobalIntDiscriminatorChild)
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
      config_override :discriminator_key, "test"

      before do

        class PreGlobalIntDiscriminatorParent
          include Mongoid::Document
        end

        class PreGlobalIntDiscriminatorChild < PreGlobalIntDiscriminatorParent
        end
      end

      after do
        Object.send(:remove_const, :PreGlobalIntDiscriminatorParent)
        Object.send(:remove_const, :PreGlobalIntDiscriminatorChild)
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

      after do
        Object.send(:remove_const, :LocalIntDiscriminatorParent)
        Object.send(:remove_const, :LocalIntDiscriminatorChild)
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

      after do
        Object.send(:remove_const, :PreLocalIntDiscriminatorParent)
        Object.send(:remove_const, :PreLocalIntDiscriminatorChild)
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

  context "when adding to the db" do
    context "when changing the discriminator_key" do
      before do
        class DBDiscriminatorParent
          include Mongoid::Document
          self.discriminator_key = "dkey"
        end

        class DBDiscriminatorChild < DBDiscriminatorParent
        end
        DBDiscriminatorChild.create!
      end

      after do
        Object.send(:remove_const, :DBDiscriminatorParent)
        Object.send(:remove_const, :DBDiscriminatorChild)
      end

      it "has the correct count" do
        expect(DBDiscriminatorChild.count).to eq(1)
      end

      it "has the correct count in the parent" do
        expect(DBDiscriminatorParent.count).to eq(1)
      end
    end

    context "when changing the discriminator_key after saving to the db" do
      before do
        class DBDiscriminatorParent
          include Mongoid::Document
        end

        class DBDiscriminatorChild < DBDiscriminatorParent
        end
        DBDiscriminatorChild.create!
        DBDiscriminatorParent.discriminator_key = "dkey2"
        DBDiscriminatorChild.create!
      end

      after do
        Object.send(:remove_const, :DBDiscriminatorParent)
        Object.send(:remove_const, :DBDiscriminatorChild)
      end

      it "only finds the documents with the new discriminator key" do
        expect(DBDiscriminatorChild.count).to eq(1)
      end

      it "has the correct count in the parent" do
        expect(DBDiscriminatorParent.count).to eq(2)
      end
    end
  end

  context "documentation tests" do

    context "Example 1" do
      before do
        class Example1Shape
          include Mongoid::Document
          field :x, type: Integer
          field :y, type: Integer
          embedded_in :canvas

          self.discriminator_key = "shape_type"
        end

        class Example1Circle < Example1Shape
          field :radius, type: Float
        end

        class Example1Rectangle < Example1Shape
          field :width, type: Float
          field :height, type: Float
        end
      end

      after do
        Object.send(:remove_const, :Example1Shape)
        Object.send(:remove_const, :Example1Circle)
        Object.send(:remove_const, :Example1Rectangle)
      end

      let(:rectangle) do
        Example1Rectangle.new
      end

      let(:circle) do
        Example1Circle.new
      end

      it "has the new discriminator key: Rectangle" do
        expect(rectangle.shape_type).to eq("Example1Rectangle")
      end

      it "does not have the default discriminator key: Rectangle" do
        expect(defined?(rectangle._type)).to be nil
      end

      it "has the new discriminator key: Circle" do
        expect(circle.shape_type).to eq("Example1Circle")
      end

      it "does not have the default discriminator key: Circle" do
        expect(defined?(circle._type)).to be nil
      end
    end

    context "Example 2" do
      before do
        class Example2Shape
          include Mongoid::Document
          field :x, type: Integer
          field :y, type: Integer
          embedded_in :canvas
        end

        class Example2Circle < Example2Shape
          field :radius, type: Float
        end

        class Example2Rectangle < Example2Shape
          field :width, type: Float
          field :height, type: Float
        end

        Example2Shape.discriminator_key = "shape_type"
      end

      after do
        Example2Shape.discriminator_key = "_type"
        Object.send(:remove_const, :Example2Shape)
        Object.send(:remove_const, :Example2Circle)
        Object.send(:remove_const, :Example2Rectangle)
      end

      let(:rectangle) do
        Example2Rectangle.new
      end

      let(:circle) do
        Example2Circle.new
      end

      it "has the new discriminator key: Rectangle" do
        expect(rectangle.shape_type).to eq("Example2Rectangle")
      end

      it "has default discriminator key: Rectangle" do
        expect(rectangle._type).to eq("Example2Rectangle")
      end

      it "has the new discriminator key: Circle" do
        expect(circle.shape_type).to eq("Example2Circle")
      end

      it "has default discriminator key: Circle" do
        expect(circle._type).to eq("Example2Circle")
      end
    end

    context "Example 3" do
      config_override :discriminator_key, "shape_type"

      before do
        class Example3Shape
          include Mongoid::Document
          field :x, type: Integer
          field :y, type: Integer
          embedded_in :canvas
        end

        class Example3Circle < Example3Shape
          field :radius, type: Float
        end

        class Example3Rectangle < Example3Shape
          field :width, type: Float
          field :height, type: Float
        end

      end

      after do
        Object.send(:remove_const, :Example3Shape)
        Object.send(:remove_const, :Example3Circle)
        Object.send(:remove_const, :Example3Rectangle)
      end

      let(:rectangle) do
        Example3Rectangle.new
      end

      let(:circle) do
        Example3Circle.new
      end

      it "has the new discriminator key: Rectangle" do
        expect(rectangle.shape_type).to eq("Example3Rectangle")
      end

      it "does not have the default discriminator key: Rectangle" do
        expect(defined?(rectangle._type)).to be nil
      end

      it "has the new discriminator key: Circle" do
        expect(circle.shape_type).to eq("Example3Circle")
      end

      it "does not have the default discriminator key: Circle" do
        expect(defined?(circle._type)).to be nil
      end
    end
  end
end
