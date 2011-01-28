require "spec_helper"

describe Mongoid::Extensions::ObjectId::Conversions do

  let(:object_id) do
    BSON::ObjectId.new
  end

  let(:object_id_string) do
    object_id.to_s
  end

  let(:composite_key) do
    "21-jump-street"
  end

  describe ".convert" do

    context "when the class is using object ids" do

      context "when provided a single object id" do

        let(:converted) do
          BSON::ObjectId.convert(Person, object_id)
        end

        it "returns the object id" do
          converted.should == object_id
        end
      end

      context "when provided an array of object ids" do

      end

      context "when provided a single string" do

        context "when the string is a valid object id" do

        end

        context "when the string is not a valid object id" do

        end
      end

      context "when providing an array of strings" do

        context "when the strings are valid object ids" do

        end

        context "when the strings are not valid object ids" do

        end
      end

      context "when provided a hash" do

        context "when the hash key is _id" do

        end

        context "when the hash key is id" do

        end

        context "when the hash key is not an id" do

        end
      end
    end

    context "when the class is not using object ids" do

    end
  end


  # describe ".cast!" do

    # context "when not using object ids" do

      # before do
        # Person.identity :type => String
      # end

      # it "returns args" do
        # BSON::ObjectId.cast!(Person, "foo").should == "foo"
      # end

    # end

    # context "when using object ids" do

      # before do
        # Person.identity :type => BSON::ObjectId
      # end

      # it "transforms String args to BSON::ObjectIds" do
        # id = BSON::ObjectId.new
        # BSON::ObjectId.cast!(Person, id.to_s).should == id
      # end

      # it "transforms all Strings inside an Array" do
        # ids = [BSON::ObjectId.new, BSON::ObjectId.new]
        # BSON::ObjectId.cast!(Person, ids.map(&:to_s)).should == ids
      # end

      # context "when casting is false" do

        # it "doesnt change the argument types" do
          # id = BSON::ObjectId.new
          # BSON::ObjectId.cast!(Person, id.to_s, false).should == id.to_s
        # end
      # end
    # end
  # end

  # describe ".get" do

    # it "returns self" do
      # BSON::ObjectId.get(object_id).should == object_id
    # end

  # end

  # describe ".set" do

    # let(:object_id_string) { "4c52c439931a90ab29000003" }

    # context "with a blank string" do
      # it "returns nil" do
        # BSON::ObjectId.set("").should be_nil
      # end
    # end

    # context "with a populated string" do
      # it "returns ObjectID" do
        # BSON::ObjectId.set(object_id_string).should ==
          # BSON::ObjectId.from_string(object_id_string)
      # end
    # end

    # context "with an ObjectID" do
      # it "returns self" do
        # BSON::ObjectId.set(object_id).should == object_id
      # end
    # end
  # end
end
