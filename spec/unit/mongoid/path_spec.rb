require "spec_helper"

describe Mongoid::Path do

  describe "#path" do

    let(:person) do
      Person.new
    end

    let(:address) do
      Address.new
    end

    let(:location) do
      Location.new
    end

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
        Location.route.should == "addresses.locations"
      end
    end
  end
end
