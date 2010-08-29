require "spec_helper"

describe Mongoid::Extensions::ObjectId::Conversions do

  let(:object_id) { BSON::ObjectId.new }

  describe ".cast!" do

    context "when not using object ids" do

      before do
        Person.identity :type => String
      end

      it "returns args" do
        BSON::ObjectId.cast!(Person, "foo").should == "foo"
      end

    end

    context "when using object ids" do

      before do
        Person.identity :type => BSON::ObjectId
      end

      it "transforms String args to BSON::ObjectIds" do
        id = BSON::ObjectId.new
        BSON::ObjectId.cast!(Person, id.to_s).should == id
      end

      it "transforms all Strings inside an Array" do
        ids = [BSON::ObjectId.new, BSON::ObjectId.new]
        BSON::ObjectId.cast!(Person, ids.map(&:to_s)).should == ids
      end

      context "when casting is false" do

        it "doesnt change the argument types" do
          id = BSON::ObjectId.new
          BSON::ObjectId.cast!(Person, id.to_s, false).should == id.to_s
        end
      end
    end
  end

  describe ".get" do

    it "returns self" do
      BSON::ObjectId.get(object_id).should == object_id
    end

  end

  describe ".set" do

    let(:object_id_string) { "4c52c439931a90ab29000003" }

    context "with a blank string" do
      it "returns nil" do
        BSON::ObjectId.set("").should be_nil
      end
    end

    context "with a populated string" do
      it "returns ObjectID" do
        BSON::ObjectId.set(object_id_string).should ==
          BSON::ObjectId.from_string(object_id_string)
      end
    end

    context "with an ObjectID" do
      it "returns self" do
        BSON::ObjectId.set(object_id).should == object_id
      end
    end
  end
end
