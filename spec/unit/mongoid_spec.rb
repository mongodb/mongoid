require "spec_helper"

describe Mongoid do

  describe ".database=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { Mongoid.database = "Test" }.should raise_error
      end

    end

  end

  describe ".raise_not_found_error" do

    before do
      Mongoid.raise_not_found_error = false
    end

    it "sets the not found error flag" do
      Mongoid.raise_not_found_error.should == false
    end

  end

end
