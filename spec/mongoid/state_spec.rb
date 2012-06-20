require "spec_helper"

describe Mongoid::State do

  describe "#new_record?" do

    context "when calling new on the document" do

      let(:person) do
        Person.new("_id" => Moped::BSON::ObjectId.new)
      end

      it "returns true" do
        person.should be_a_new_record
      end
    end

    context "when the object has been saved" do

      let(:person) do
        Person.instantiate("_id" => Moped::BSON::ObjectId.new)
      end

      it "returns false" do
        person.should_not be_a_new_record
      end
    end

    context "when the object has not been saved" do

      let(:person) do
        Person.new
      end

      it "returns true" do
        person.should be_a_new_record
      end
    end
  end

  describe "#persisted?" do

    let(:person) do
      Person.new
    end

    it "delegates to new_record?" do
      person.should_not be_persisted
    end

    context "when the object has been destroyed" do
      before do
        person.save
        person.destroy
      end

      it "returns false" do
        person.should_not be_persisted
      end
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
        person.should be_destroyed
      end
    end

    context "when destroyed is false" do

      before do
        person.destroyed = false
      end

      it "returns true" do
        person.should_not be_destroyed
      end
    end

    context "when destroyed is nil" do

      before do
        person.destroyed = nil
      end

      it "returns false" do
        person.should_not be_destroyed
      end
    end
  end
end
