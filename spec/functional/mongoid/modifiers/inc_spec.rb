require "spec_helper"

describe Mongoid::Modifiers::Inc do

  describe "#inc" do

    let(:person) do
      Person.create(:ssn => "777-66-1010")
    end

    before do
      person.inc(:age, 2)
    end

    it "increments the field by the value" do
      person.age.should == 102
    end

    it "updates the database with the new value" do
      person.reload.age.should == 102
    end
  end
end
