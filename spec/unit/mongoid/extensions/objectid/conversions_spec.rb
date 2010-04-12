require "spec_helper"

describe Mongoid::Extensions::ObjectID::Conversions do

  let(:object_id) do
    BSON::ObjectID.new
  end

  describe "#get" do

    it "returns self" do
      BSON::ObjectID.get(object_id).should == object_id
    end
  end

  describe "#set" do

    it "returns self" do
      BSON::ObjectID.set(object_id).should == object_id
    end
  end
end
