require "spec_helper"

describe Mongoid::Modifiers::Inc do

  describe "#inc" do

    before(:all) { Person.delete_all }
    after(:all)  { Person.delete_all }

    let(:person) do
      Person.create(:ssn => "777-66-1010")
    end

    before do
      person.inc(:age, 2)
      person.inc(:score, 2)
      person.inc(:high_score, 5)
    end

    it "increments the field by the value" do
      person.age.should == 102
    end

    it "updates the database with the new value" do
      person.reload.age.should == 102
    end

    it "increments nil field by the value" do
      person.score.should == 2
    end

    it "sets and increments non-existent field by the value" do
      person.high_score.should == 5
    end
  end
end
