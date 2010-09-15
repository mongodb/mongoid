require "spec_helper"

describe Mongoid::Extensions::ObjectId::Conversions do

  let(:object_id) do
    BSON::ObjectId.new
  end

  describe "#get" do

    it "returns self" do
      BSON::ObjectId.get(object_id).should == object_id
    end
  end

  describe "#set" do

    it "returns self" do
      BSON::ObjectId.set(object_id).should == object_id
    end
  end
end
