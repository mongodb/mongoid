require "spec_helper"

describe Mongoid::Factory do

  describe ".build" do

    context "when the _type attribute is present" do

      before do
        @attributes = { "_type" => "Person", "title" => "Sir" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end

    context "when _type is not preset" do

      before do
        @attributes = { "title" => "Sir" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end

    context "when _type is an empty string" do

      before do
        @attributes = { "title" => "Sir", "_type" => "" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end
  end
end
