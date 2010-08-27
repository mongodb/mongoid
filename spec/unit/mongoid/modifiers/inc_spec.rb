require "spec_helper"

describe Mongoid::Modifiers::Inc do

  before do
    @collection = stub
    Person.stubs(:collection).returns(@collection)
  end

  let(:person) do
    Person.new
  end

  describe "#persist" do

    context "when safe mode provided" do

      let(:inc) do
        Mongoid::Modifiers::Inc.new(person, :safe => true)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$inc" => { :age => 5 } },
          :safe => true,
          :multi => false
        ).returns(true)
      end

      it "increments with the safe mode in the options" do
        inc.persist(:age, 5)
      end
    end

    context "when safe mode not provided" do

      let(:inc) do
        Mongoid::Modifiers::Inc.new(person)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$inc" => { :age => 5 } },
          :safe => false,
          :multi => false
        ).returns(true)
      end

      it "increments with safe mode as globally defined" do
        inc.persist(:age, 5)
      end
    end

    context "in conjunction with dirty attributes" do

      let(:inc) do
        Mongoid::Modifiers::Inc.new(person, :safe => true)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$inc" => { :age => 5 } },
          :safe => true,
          :multi => false
        ).returns(true)
        inc.persist(:age, 5)
      end

      it "does not mark the field as dirty" do
        person.changes[:age].should be_nil
      end
    end
  end
end
