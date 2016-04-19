require "spec_helper"

describe Object do
  using Mongoid::Refinements

  describe "#evolve_object_id" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      expect(object.evolve_object_id).to eq(object)
    end
  end

  describe "#as_find_arguments" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      expect(object.as_find_arguments).to eq(object)
    end
  end

  describe "#mongoize_object_id" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      expect(object.mongoize_object_id).to eq(object)
    end
  end

  describe ".mongoize_fk" do

    context "when the related model uses object ids" do

      let(:metadata) do
        Game.relations["person"]
      end

      let(:constraint) do
        metadata.constraint
      end

      context "when provided an object id" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:fk) do
          Object.mongoize_fk(constraint, object_id)
        end

        it "returns the object id" do
          expect(fk).to eq(object_id)
        end
      end

      context "when provided a string" do

        context "when the string is a legal object id" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          let(:fk) do
            Object.mongoize_fk(constraint, object_id.to_s)
          end

          it "returns the object id" do
            expect(fk).to eq(object_id)
          end
        end

        context "when the string is not a legal object id" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Object.mongoize_fk(constraint, string)
          end

          it "returns the string" do
            expect(fk).to eq(string)
          end
        end

        context "when the string is blank" do

          let(:fk) do
            Object.mongoize_fk(constraint, "")
          end

          it "returns nil" do
            expect(fk).to be_nil
          end
        end
      end

      context "when provided nil" do

        let(:fk) do
          Object.mongoize_fk(constraint, nil)
        end

        it "returns nil" do
          expect(fk).to be_nil
        end
      end

      context "when provided an empty array" do

        let(:fk) do
          Object.mongoize_fk(constraint, [])
        end

        it "returns an empty array" do
          expect(fk).to eq([])
        end
      end
    end
  end

  describe "#mongoize_time" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      expect(object.mongoize_time).to eq(object)
    end
  end

  describe "#sortable" do

    let(:object) do
      Object.new
    end

    it "returns self" do
      expect(object.sortable).to eq(object)
    end
  end

  describe ".demongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      expect(Object.demongoize(object)).to eq(object)
    end
  end

  describe "#do_or_do_not" do

    context "when the object is nil" do

      let(:result) do
        nil.do_or_do_not(:not_a_method, "The force is strong with you")
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the object is not nil" do

      context "when the object responds to the method" do

        let(:result) do
          [ "Yoda", "Luke" ].do_or_do_not(:join, ",")
        end

        it "returns the result of the method" do
          expect(result).to eq("Yoda,Luke")
        end
      end

      context "when the object does not respond to the method" do

        let(:result) do
          "Yoda".do_or_do_not(:use, "The Force", 1000)
        end

        it "returns the result of the method" do
          expect(result).to be_nil
        end
      end
    end
  end

  describe ".mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      expect(Object.mongoize(object)).to eq(object)
    end
  end

  describe "#mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the object" do
      expect(object.mongoize).to eq(object)
    end
  end

  describe "#resizable?" do

    it "returns false" do
      expect(Object.new.resizable?).to be false
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
        expect(result).to be_nil
      end
    end
  end

  describe "#remove_ivar" do

    context "when the instance variable is defined" do

      let(:document) do
        Person.new
      end

      before do
        document.instance_variable_set(:@_testing, "testing")
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "removes the instance variable" do
        expect(document.instance_variable_defined?(:@_testing)).to be false
      end

      it "returns the value" do
        expect(removal).to eq("testing")
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
        expect(removal).to be false
      end
    end
  end

  describe "#__add__" do

    context "when the other object is a non-enumerable" do

      context "when the values are unique" do

        it "returns an array of both" do
          expect(5.__add__(6)).to eq([ 5, 6 ])
        end
      end

      context "when the values are not unique" do

        it "returns the original value" do
          expect(5.__add__(5)).to eq(5)
        end
      end
    end

    context "when the other object is an array" do

      context "when the values are unique" do

        it "returns an array of both" do
          expect(5.__add__([ 6, 7 ])).to eq([ 5, 6, 7 ])
        end
      end

      context "when the values are not unique" do

        it "returns a unique array of both" do
          expect(5.__add__([ 5, 6, 7 ])).to eq([ 5, 6, 7 ])
        end
      end
    end
  end

  describe "#__intersect__" do

    context "when the other object is a non-enumerable" do

      context "when the values intersect" do

        it "returns an intersected array" do
          expect(5.__intersect__(5)).to eq([ 5 ])
        end
      end

      context "when the values do not intersect" do

        it "returns an empty array" do
          expect(5.__intersect__(6)).to be_empty
        end
      end
    end

    context "when the other object is an array" do

      context "when the values intersect" do

        it "returns an intersected array" do
          expect(5.__intersect__([ 5, 6 ])).to eq([ 5 ])
        end
      end

      context "when the values do not intersect" do

        it "returns an empty array " do
          expect(5.__intersect__([ 6, 7 ])).to be_empty
        end
      end
    end
  end

  describe "#__union__" do

    context "when the other object is a non-enumerable" do

      context "when the values are the same" do

        it "returns an unioned array" do
          expect(5.__union__(5)).to eq([ 5 ])
        end
      end

      context "when the values are not the same" do

        it "returns an empty array" do
          expect(5.__union__(6)).to eq([ 5, 6 ])
        end
      end
    end

    context "when the other object is an array" do

      context "when the values are not the same" do

        it "returns an unioned array" do
          expect(5.__union__([ 5, 6 ])).to eq([ 5, 6 ])
        end
      end
    end
  end
end
