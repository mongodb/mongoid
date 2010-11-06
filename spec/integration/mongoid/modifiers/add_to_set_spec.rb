require "spec_helper"

describe Mongoid::Modifiers::AddToSet do

  describe "#inc" do

    let(:person) do
      Person.create(:ssn => "777-66-1010")
    end

    before do
      person.add_to_set(:aliases, 'Harry')
      person.add_to_set(:aliases, 'Lloyd')
    end

    it "adds the value to the array" do
      person.aliases.should == ['Harry','Lloyd']
    end

    it "updates the database with the new value" do
      person.reload.aliases.should == ['Harry','Lloyd']
    end
  end
end
