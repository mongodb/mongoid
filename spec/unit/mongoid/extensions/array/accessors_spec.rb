require "spec_helper"

describe Mongoid::Extensions::Array::Accessors do

  describe "#update" do

    context "when the attributes exist" do

      before do
        @array = [{ :_id => 1, :name => "James T. Kirk" }]
      end

      it "overwrites with the new attributes" do
        @array.update({ :_id => 1, :name => "Spock" })
        @array.first[:name].should == "Spock"
      end

    end

    context "when the attributes do not exist" do

      before do
        @array = [{ :_id => 1, :name => "James T. Kirk" }]
      end

      it "appends the new attributes" do
        @array.update({ :_id => 2, :name => "Scotty" })
        @array.size.should == 2
        @array.last[:name].should == "Scotty"
      end

    end

    context "when the new attribtues have no id" do

      before do
        @array = [{ :_id => 1, :name => "James T. Kirk" }]
      end

      it "appends the new attributes" do
        @array.update({:name => "Scotty" })
        @array.size.should == 2
        @array.last[:name].should == "Scotty"
      end

    end

  end

end
