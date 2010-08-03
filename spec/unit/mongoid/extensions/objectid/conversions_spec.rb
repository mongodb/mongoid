require "spec_helper"

describe Mongoid::Extensions::ObjectID::Conversions do

  let(:object_id) do
    BSON::ObjectID.new
  end

  let(:object_id_string) do
    "4c52c439931a90ab29000003"
  end

  describe "#get" do

    it "returns self" do
      BSON::ObjectID.get(object_id).should == object_id
    end

  end

  describe "#set with ObjectID" do

    it "returns self" do
      BSON::ObjectID.set(object_id).should == object_id
    end

  end

  describe "#set with String" do

    it "returns ObjectID" do
      BSON::ObjectID.set(object_id_string).should == BSON::ObjectID.from_string(object_id_string)
    end

  end

end
