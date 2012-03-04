require "spec_helper"

describe Mongoid::Extensions::Object do

  describe "#_deep_copy" do

    context "when the object is cloneable" do

      let(:string) do
        "testing"
      end

      let(:copy) do
        string._deep_copy
      end

      it "returns an equal object" do
        copy.should eq(string)
      end

      it "returns a new instance" do
        copy.should_not equal(string)
      end
    end

    context "when the object is not cloneable" do

      let(:number) do
        1
      end

      let(:copy) do
        number._deep_copy
      end

      it "returns the same object" do
        copy.should equal(number)
      end
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

  describe ".re_define_method" do

    context "when the method already exists" do

      class Smoochy
        def sing
          "singing"
        end
      end

      before do
        Smoochy.re_define_method("sing") do
          "singing again"
        end
      end

      it "redefines the existing method" do
        Smoochy.new.sing.should eq("singing again")
      end
    end

    context "when the method does not exist" do

      class Rhino
      end

      before do
        Rhino.re_define_method("sing") do
          "singing"
        end
      end

      it "redefines the existing method" do
        Rhino.new.sing.should eq("singing")
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
