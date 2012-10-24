require "spec_helper"

describe Mongoid::Persistence::Atomic do

  context "when using aliased field names" do

    describe "#add_to_set" do

      let(:person) do
        Person.create(array: [ "test" ])
      end

      before do
        person.add_to_set(:array, "testy")
      end

      it "adds to the aliased field" do
        person.array.should eq([ "test", "testy" ])
      end

      it "persists the change" do
        person.reload.array.should eq([ "test", "testy" ])
      end
    end

    describe "#bit" do

      let(:person) do
        Person.create(inte: 60)
      end

      before do
        person.bit(:inte, { and: 13 })
      end

      it "performs the bitwise operation" do
        person.inte.should eq(12)
      end

      it "persists the changes" do
        person.reload.inte.should eq(12)
      end
    end

    describe "#inc" do

      let(:person) do
        Person.create(inte: 5)
      end

      before do
        person.inc(:inte, 1)
      end

      it "increments the aliased field" do
        person.inte.should eq(6)
      end

      it "persists the change" do
        person.reload.inte.should eq(6)
      end
    end

    describe "#pop" do

      let(:person) do
        Person.create(array: [ "test1", "test2" ])
      end

      before do
        person.pop(:array, 1)
      end

      it "removes from the aliased field" do
        person.array.should eq([ "test1" ])
      end

      it "persists the change" do
        person.reload.array.should eq([ "test1" ])
      end
    end

    describe "#pull" do

      let(:person) do
        Person.create(array: [ "test1", "test2" ])
      end

      before do
        person.pull(:array, "test1")
      end

      it "removes from the aliased field" do
        person.array.should eq([ "test2" ])
      end

      it "persists the change" do
        person.reload.array.should eq([ "test2" ])
      end
    end

    describe "#pull_all" do

      let(:person) do
        Person.create(array: [ "test1", "test2" ])
      end

      before do
        person.pull_all(:array, [ "test1", "test2" ])
      end

      it "removes from the aliased field" do
        person.array.should be_empty
      end

      it "persists the change" do
        person.reload.array.should be_empty
      end
    end

    describe "#push" do

      let(:person) do
        Person.create(array: [ "test" ])
      end

      before do
        person.push(:array, "testy")
      end

      it "adds to the aliased field" do
        person.array.should eq([ "test", "testy" ])
      end

      it "persists the change" do
        person.reload.array.should eq([ "test", "testy" ])
      end
    end

    describe "#push_all" do

      let(:person) do
        Person.create(array: [ "test" ])
      end

      before do
        person.push_all(:array, [ "testy", "test2" ])
      end

      it "adds to the aliased field" do
        person.array.should eq([ "test", "testy", "test2" ])
      end

      it "persists the change" do
        person.reload.array.should eq([ "test", "testy", "test2" ])
      end
    end

    describe "#rename" do

      let(:person) do
        Person.create(inte: 5)
      end

      before do
        person.rename(:inte, :integer)
      end

      it "renames the aliased field" do
        person.integer.should eq(5)
      end

      it "persists the change" do
        person.reload.integer.should eq(5)
      end
    end

    describe "#set" do

      let(:person) do
        Person.create(inte: 5)
      end

      before do
        person.set(:inte, 8)
      end

      it "sets the aliased field" do
        person.inte.should eq(8)
      end

      it "persists the change" do
        person.reload.inte.should eq(8)
      end
    end

    describe "#unset" do

      let(:person) do
        Person.create(inte: 5)
      end

      before do
        person.unset(:inte)
      end

      it "unsets the aliased field" do
        person.inte.should be_nil
      end

      it "persists the change" do
        person.reload.inte.should be_nil
      end
    end
  end
end
