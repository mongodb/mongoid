require "spec_helper"

describe Mongoid::Keys do

  describe ".identity" do

    context "when provided a type" do

      before do
        Address.identity :type => String
      end

      after do
        Address.identity :type => BSON::ObjectId
      end

      it "sets the type of the id" do
        Address._id_type.should == String
      end
    end
  end

  describe ".key" do

    context "when key is single field" do

      before do
        Address.key :street
        @address = Address.new(:street => "Testing Street Name")
      end

      it "adds the callback for primary key generation" do
        @address.run_callbacks(:save)
        @address.id.should == "testing-street-name"
      end

      it "changes the _id_type to a string" do
        @address._id_type.should == String
      end
    end

    context "when key is composite" do

      before do
        Address.key :street, :post_code
        @address = Address.new(:street => "Testing Street Name", :post_code => "94123")
      end

      it "combines all fields" do
        @address.run_callbacks(:save)
        @address.id.should == "testing-street-name-94123"
      end
    end

    context "when key is on a subclass" do

      before do
        Firefox.key :name
      end

      it "sets the key for the entire hierarchy" do
        Canvas.primary_key.should == [:name]
      end
    end
  end

  describe "#using_object_ids?" do

    context "when id type is an object id" do

      before do
        Address.identity :type => BSON::ObjectId
      end

      let(:address) do
        Address.new
      end

      it "returns true" do
        address.should be_using_object_ids
      end
    end

    context "when id type is not an object id" do

      before do
        Address.identity :type => String
      end

      let(:address) do
        Address.new
      end

      it "returns false" do
        address.should_not be_using_object_ids
      end
    end
  end
end
