require "spec_helper"

describe Mongoid::Persistence::Atomic::Inc do

  before do
    Person.delete_all
  end

  describe "#inc" do

    let(:person) do
      Person.create(:ssn => "777-66-1010", :age => 100)
    end

    let(:reloaded) do
      person.reload
    end

    context "when incrementing a field on an embedded document" do

      let(:address) do
        person.addresses.create(:street => "Tauentzienstr", :number => 5)
      end

      let!(:inced) do
        address.inc(:number, 5)
      end

      it "increments the provided value" do
        inced.should == 10
      end

      it "persists the change" do
        reloaded.addresses.first.number.should == 10
      end
    end

    context "when incrementing a field with a value" do

      let!(:inced) do
        person.inc(:age, 2)
      end

      it "increments by the provided value" do
        person.age.should == 102
      end

      it "returns the new value" do
        inced.should == 102
      end

      it "persists the changes" do
        reloaded.age.should == 102
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when incrementing a nil field" do

      let!(:inced) do
        person.inc(:score, 2)
      end

      it "sets the value to the provided number" do
        person.score.should == 2
      end

      it "returns the new value" do
        inced.should == 2
      end

      it "persists the changes" do
        reloaded.score.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["score"].should be_nil
      end
    end

    context "when incrementing a non existant field" do

      let!(:inced) do
        person.inc(:high_score, 5)
      end

      it "sets the value to the provided number" do
        person.high_score.should == 5
      end

      it "returns the new value" do
        inced.should == 5
      end

      it "persists the changes" do
        reloaded.high_score.should == 5
      end

      it "resets the dirty attributes" do
        person.changes["high_score"].should be_nil
      end
    end
  end
end
