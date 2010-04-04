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

  let(:name) do
    Name.new
  end

  describe "#remover" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is root" do

      it "returns nil" do
        person.remover.should be_nil
      end
    end

    context "when document is an embeds_one" do

      it "returns $unset" do
        name.remover.should == "$unset"
      end
    end

    context "when document is an embeds_many" do

      it "returns $set" do
        address.remover.should == "$set"
      end
    end
  end

  describe "#inserter" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is root" do

      it "returns nil" do
        person.inserter.should be_nil
      end
    end

    context "when document is an embeds_one" do

      it "returns $set" do
        name.inserter.should == "$set"
      end
    end

    context "when document is an embeds_many" do

      it "returns $push" do
        address.inserter.should == "$push"
      end
    end
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

      context "when the document is new" do

        it "returns the path without index" do
          address.position.should == "addresses"
        end
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the path plus index" do
          address.position.should == "addresses.0"
        end
      end
    end

    context "when document embedded multiple levels" do

      before do
        @other = Location.new
        address.locations << [ @other, location ]
        address.instance_variable_set(:@new_record, false)
        person.addresses << address
      end

      context "when the document is new" do

        it "returns the path with parent indexes" do
          location.position.should == "addresses.0.locations"
        end
      end

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the path plus index" do
          location.position.should == "addresses.0.locations.1"
        end
      end
    end
  end
end
