require "spec_helper"

describe Mongoid::Modifiers do

  describe "#inc" do

    let(:person) do
      Person.new
    end

    let(:inc) do
      stub
    end

    before do
      Mongoid::Modifiers::Inc.expects(:new).with(person, {}).returns(inc)
      inc.expects(:persist).with(:age, 5)
    end

    it "persists the $inc modifier" do
      person.inc(:age, 5)
    end

    it "returns the new field value" do
      person.inc(:age, 5).should == 105
    end
  end
end
