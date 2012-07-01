require "spec_helper"

describe Mongoid::Extensions::Object do

  describe "#__evolve_object_id__" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      object.__evolve_object_id__.should eq(object)
    end
  end

  describe "#__find_args__" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      object.__find_args__.should eq(object)
    end
  end

  describe "#__mongoize_object_id__" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      object.__mongoize_object_id__.should eq(object)
    end
  end

  describe ".__mongoize_fk__" do

    context "when the related model uses object ids" do

      let(:metadata) do
        Game.relations["person"]
      end

      let(:constraint) do
        metadata.constraint
      end

      context "when provided an object id" do

        let(:object_id) do
          Moped::BSON::ObjectId.new
        end

        let(:fk) do
          Object.__mongoize_fk__(constraint, object_id)
        end

        it "returns the object id" do
          fk.should eq(object_id)
        end
      end

      context "when provided a string" do

        context "when the string is a legal object id" do

          let(:object_id) do
            Moped::BSON::ObjectId.new
          end

          let(:fk) do
            Object.__mongoize_fk__(constraint, object_id.to_s)
          end

          it "returns the object id" do
            fk.should eq(object_id)
          end
        end

        context "when the string is not a legal object id" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Object.__mongoize_fk__(constraint, string)
          end

          it "returns the string" do
            fk.should eq(string)
          end
        end

        context "when the string is blank" do

          let(:fk) do
            Object.__mongoize_fk__(constraint, "")
          end

          it "returns nil" do
            fk.should be_nil
          end
        end
      end

      context "when provided nil" do

        let(:fk) do
          Object.__mongoize_fk__(constraint, nil)
        end

        it "returns nil" do
          fk.should be_nil
        end
      end

      context "when provided an empty array" do

        let(:fk) do
          Object.__mongoize_fk__(constraint, [])
        end

        it "returns an empty array" do
          fk.should eq([])
        end
      end
    end
  end

  describe "#__mongoize_time__" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      object.__mongoize_time__.should eq(object)
    end
  end

  describe "#__sortable__" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      object.__sortable__.should eq(object)
    end
  end

  describe ".demongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      Object.demongoize(object).should eq(object)
    end
  end

  describe "#do_or_do_not" do

    context "when the object is nil" do

      let(:result) do
        nil.do_or_do_not(:not_a_method, "The force is strong with you")
      end

      it "returns nil" do
        result.should be_nil
      end
    end

    context "when the object is not nil" do

      context "when the object responds to the method" do

        let(:result) do
          [ "Yoda", "Luke" ].do_or_do_not(:join, ",")
        end

        it "returns the result of the method" do
          result.should eq("Yoda,Luke")
        end
      end

      context "when the object does not respond to the method" do

        let(:result) do
          "Yoda".do_or_do_not(:use, "The Force", 1000)
        end

        it "returns the result of the method" do
          result.should be_nil
        end
      end
    end
  end

  describe ".mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      Object.mongoize(object).should eq(object)
    end
  end

  describe "#mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the object" do
      object.mongoize.should eq(object)
    end
  end

  describe "#resizable?" do

    it "returns false" do
      Object.new.should_not be_resizable
    end
  end

  describe "#you_must" do

    context "when the object is frozen" do

      let(:person) do
        Person.new.tap { |peep| peep.freeze }
      end

      let(:result) do
        person.you_must(:aliases=, [])
      end

      it "returns nil" do
        result.should be_nil
      end
    end
  end

  describe "#remove_ivar" do

    context "when the instance variable is defined" do

      let(:document) do
        Person.new
      end

      before do
        document.instance_variable_set(:@testing, "testing")
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "removes the instance variable" do
        document.instance_variable_defined?(:@testing).should be_false
      end

      it "returns true" do
        removal.should be_true
      end
    end

    context "when the instance variable is not defined" do

      let(:document) do
        Person.new
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "returns false" do
        removal.should be_false
      end
    end
  end
end
