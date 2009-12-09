require "spec_helper"

describe Mongoid do

  describe ".database=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { Mongoid.database = "Test" }.should raise_error
      end

    end

  end

end
