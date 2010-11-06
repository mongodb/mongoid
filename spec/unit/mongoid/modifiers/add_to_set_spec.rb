require "spec_helper"

describe Mongoid::Modifiers::AddToSet do

  before do
    @collection = stub
    Person.stubs(:collection).returns(@collection)
  end

  let(:person) do
    Person.new
  end

  describe "#persist" do

    context "when safe mode provided" do

      let(:add_to_set) do
        Mongoid::Modifiers::AddToSet.new(person, :safe => true)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$addToSet" => { :aliases => 'Harry' } },
          :safe => true,
          :multi => false
        ).returns(true)
      end

      it "adds to set with the safe mode in the options" do
        add_to_set.persist(:aliases, 'Harry')
      end
    end

    context "when safe mode not provided" do

      let(:add_to_set) do
        Mongoid::Modifiers::AddToSet.new(person)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$addToSet" => { :aliases => 'Harry' } },
          :safe => false,
          :multi => false
        ).returns(true)
      end

      it "adds to set with safe mode as globally defined" do
        add_to_set.persist(:aliases, 'Harry')
      end
    end

    context "in conjunction with dirty attributes" do

      let(:add_to_set) do
        Mongoid::Modifiers::AddToSet.new(person, :safe => true)
      end

      before do
        @collection.expects(:update).with(
          person._selector,
          { "$addToSet" => { :aliases => 'Harry' } },
          :safe => true,
          :multi => false
        ).returns(true)
        add_to_set.persist(:aliases, 'Harry')
      end

      it "does not mark the field as dirty" do
        person.changes[:aliases].should be_nil
      end
    end
  end
end
