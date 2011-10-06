require "spec_helper"

describe Mongoid::Extensions::String::Checks do

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        "id".should be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        "_id".should be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        "identity".should_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        "something_id".should_not be_mongoid_id
      end
    end
  end
end
