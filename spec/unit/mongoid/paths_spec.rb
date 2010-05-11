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

  let(:agent) do
    Agent.new
  end


  let(:agent_name) do
    Name.new(:first_name => "Agent")
  end

  describe "#._remover" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is root" do

      it "returns nil" do
        person._remover.should be_nil
      end
    end

    context "when document is an embeds_one" do

      it "returns $unset" do
        name._remover.should == "$unset"
      end
    end

    context "when document is an embeds_many" do

      it "returns $pull" do
        address._remover.should == "$pull"
      end
    end
  end

  describe "#._inserter" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is root" do

      it "returns nil" do
        person._inserter.should be_nil
      end
    end

    context "when document is an embeds_one" do

      it "returns $set" do
        name._inserter.should == "$set"
      end
    end

    context "when document is an embeds_many" do

      it "returns $push" do
        address._inserter.should == "$push"
      end
    end
  end

  describe "#._path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person._path.should == ""
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the inverse_of value of the association" do
        address._path.should == "addresses"
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document" do
        location._path.should == "addresses.locations"
      end
    end

    context "when document has many inverse_of values" do
      before do
        agent.names << agent_name
        person.name = name
      end

      it "selects the right inverse_of value for the first one" do
        agent_name._path.should == "names"
      end

      it "selects the right inverse_of value for the second one" do
        name._path.should == "name"
      end
    end
  end

  describe "#._selector" do

    context "when the document is a parent" do

      it "returns an id._selector" do
        person._selector.should == { "_id" => person.id }
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the association with id._selector" do
        address._selector.should == { "_id" => person.id, "addresses._id" => address.id }
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document with ids" do
        location._selector.should ==
          { "_id" => person.id, "addresses._id" => address.id, "addresses.locations._id" => location.id }
      end
    end
  end

  describe "#._position" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person._position.should == ""
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      context "when the document is new" do

        it "returns the._path without index" do
          address._position.should == "addresses"
        end
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the._path plus index" do
          address._position.should == "addresses.0"
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

        it "returns the._path with parent indexes" do
          location._position.should == "addresses.0.locations"
        end
      end

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the._path plus index" do
          location._position.should == "addresses.0.locations.1"
        end
      end
    end
  end

  describe "#._pull" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person._pull.should == ""
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the._path without the index" do
          address._pull.should == "addresses"
        end

        context "and there are 10 or more documents" do

          before do
            10.times do
              person.addresses << address
            end
          end

          it "returns the._path without the index" do
            address._pull.should == "addresses"
          end

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

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the._path plus index" do
          location._pull.should == "addresses.0.locations"
        end

      end
    end
  end
end
