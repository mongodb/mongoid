require "spec_helper"

describe Mongoid::Paths do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new(:street => "testing")
  end

  let(:location) do
    Location.new
  end

  describe "#path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person.path.should == ""
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the inverse_of value of the association" do
        address.path.should == "addresses"
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document" do
        location.path.should == "addresses.locations"
      end

      it "sets the route class instance var" do
        Location._path.should == "addresses.locations"
      end
    end
  end

  describe "#selector" do

    context "when the document is a parent" do

      it "returns an id selector" do
        person.selector.should == { "_id" => person.id }
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the association with id selector" do
        address.selector.should == { "_id" => person.id, "addresses._id" => address.id }
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document with ids" do
        location.selector.should ==
          { "_id" => person.id, "addresses._id" => address.id, "addresses.locations._id" => location.id }
      end
    end
  end

  describe "#position" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person.position.should == ""
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the path plus $" do
        address.position.should == "addresses.$"
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the path plus $" do
        location.position.should == "addresses.locations.$"
      end

      it "sets the matcher class instance var" do
        Location._position.should == "addresses.locations.$"
      end
    end
  end
end
