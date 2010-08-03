require "spec_helper"

describe Mongoid::Extensions::ObjectID::Conversions do

  let(:object_id) { BSON::ObjectID.new }

  describe "#get" do

    it "returns self" do
      BSON::ObjectID.get(object_id).should == object_id
    end

  end

  describe "#set" do

    let(:object_id_string) { "4c52c439931a90ab29000003" }

    context "with a blank string" do
      it "returns nil" do
        BSON::ObjectID.set("").should be_nil
      end
    end

    context "with a populated string" do
      it "returns ObjectID" do
        BSON::ObjectID.set(object_id_string).should == BSON::ObjectID.from_string(object_id_string)
      end
    end

    context "with an ObjectID" do
      it "returns self" do
        BSON::ObjectID.set(object_id).should == object_id
      end
    end

  end

end
