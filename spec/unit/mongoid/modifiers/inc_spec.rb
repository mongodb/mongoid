require "spec_helper"

describe Mongoid::Modifiers::Inc do

  before do
    @collection = stub
    Person.stubs(:collection).returns(@collection)
  end

  describe "#persist" do

    context "when safe mode provided" do

      let(:inc) do
        Mongoid::Modifiers::Inc.new(Person, :safe => true)
      end

      before do
        @collection.expects(:update).with(
          { "$inc" => { :field => 5 } },
          :safe => true,
          :multi => false
        ).returns(true)
      end

      it "increments with the safe mode in the options" do
        inc.persist(:field, 5)
      end
    end

    context "when safe mode not provided" do

      let(:inc) do
        Mongoid::Modifiers::Inc.new(Person)
      end

      before do
        @collection.expects(:update).with(
          { "$inc" => { :field => 5 } },
          :safe => false,
          :multi => false
        ).returns(true)
      end

      it "increments with safe mode as globally defined" do
        inc.persist(:field, 5)
      end
    end
  end
end
