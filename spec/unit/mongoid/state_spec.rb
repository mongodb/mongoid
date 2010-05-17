require "spec_helper"

describe Mongoid::State do

  describe "#new_record?" do

    context "when calling new on the document" do

      before do
        @person = Person.new("_id" => "1")
      end

      it "returns true" do
        @person.new_record?.should == true
      end
    end

    context "when the object has been saved" do

      before do
        @person = Person.instantiate("_id" => "1")
      end

      it "returns false" do
        @person.new_record?.should be_false
      end

    end

    context "when the object has not been saved" do

      before do
        @person = Person.new
      end

      it "returns true" do
        @person.new_record?.should be_true
      end

    end

  end

  describe "#persisted?" do

    before do
      @person = Person.new
    end

    it "delegates to new_record?" do
      @person.persisted?.should be_false
    end
  end

  describe "destroyed?" do

    before do
      @person = Person.new
    end

    context "when destroyed is true" do

      before do
        @person.destroyed = true
      end

      it "returns true" do
        @person.destroyed?.should be_true
      end
    end

    context "when destroyed is false" do

      before do
        @person.destroyed = false
      end

      it "returns true" do
        @person.destroyed?.should be_false
      end
    end

    context "when destroyed is nil" do

      before do
        @person.destroyed = nil
      end

      it "returns false" do
        @person.destroyed?.should be_false
      end
    end
  end
end
