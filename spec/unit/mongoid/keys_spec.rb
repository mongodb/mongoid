require "spec_helper"

describe Mongoid::Keys do

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
end
