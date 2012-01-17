require "spec_helper"

describe Mongoid::Extensions::Object::Yoda do

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
end
