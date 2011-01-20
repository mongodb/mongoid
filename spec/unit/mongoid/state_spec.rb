require "spec_helper"

describe Mongoid::State do

  describe "#new?" do

    context "when calling new on the document" do

      let(:person) do
        person =Person.new("_id" => BSON::ObjectId.new)
      end

      it "returns true" do
        person.new?.should == true
      end
    end

    context "when the object has been saved" do

      let(:person) do
        Person.instantiate("_id" => "1")
      end

      it "returns false" do
        person.new?.should be_false
      end
    end

    context "when the object has not been saved" do

      let(:person) do
        Person.new
      end

      it "returns true" do
        person.new?.should be_true
      end
    end
  end

  describe "#new_record?" do

    context "when calling new on the document" do

      let(:person) do
        Person.new("_id" => BSON::ObjectId.new)
      end

      it "returns true" do
        person.new_record?.should == true
      end
    end

    context "when the object has been saved" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns false" do
        person.new_record?.should be_false
      end
    end

    context "when the object has not been saved" do

      let(:person) do
        Person.new
      end

      it "returns true" do
        person.new_record?.should be_true
      end
    end
  end

  describe "#persisted?" do

    let(:person) do
      Person.new
    end

    it "delegates to new_record?" do
      person.persisted?.should be_false
    end
  end

  describe "destroyed?" do

    let(:person) do
      Person.new
    end

    context "when destroyed is true" do

      before do
        person.destroyed = true
      end

      it "returns true" do
        person.destroyed?.should be_true
      end
    end

    context "when destroyed is false" do

      before do
        person.destroyed = false
      end

      it "returns true" do
        person.destroyed?.should be_false
      end
    end

    context "when destroyed is nil" do

      before do
        person.destroyed = nil
      end

      it "returns false" do
        person.destroyed?.should be_false
      end
    end
  end
end
