require "spec_helper"

describe Mongoid::Persistence::Atomic::PushAll do

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.create(aliases: [ "007" ])
      end

      let!(:pushed) do
        person.push_all(:aliases, [ "Bond", "James" ])
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        person.aliases.should eq([ "007", "Bond", "James" ])
      end

      it "persists the data" do
        reloaded.aliases.should eq([ "007", "Bond", "James" ])
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        pushed.should eq([ "007", "Bond", "James" ])
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create
      end

      let!(:pushed) do
        person.push_all(:aliases, [ "Bond", "James" ])
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        person.aliases.should eq([ "Bond", "James" ])
      end

      it "persists the data" do
        reloaded.aliases.should eq([ "Bond", "James" ])
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        pushed.should eq([ "Bond", "James" ])
      end
    end
  end
end
