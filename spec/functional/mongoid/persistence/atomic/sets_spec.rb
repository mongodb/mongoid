require "spec_helper"

describe Mongoid::Persistence::Atomic::Sets do

  before do
    Person.delete_all
  end

  describe "#set" do

    let(:person) do
      Person.create(:ssn => "777-66-1010", :age => 100)
    end

    let(:reloaded) do
      person.reload
    end

    context "when setting a field on an embedded document" do

      let(:address) do
        person.addresses.create(:street => "Tauentzienstr", :number => 5)
      end

      let!(:set) do
        address.set(:number, 5)
      end

      it "sets the provided value" do
        set.should == 5
      end

      it "persists the change" do
        reloaded.addresses.first.number.should == 5
      end
    end

    context "when setting a field with a value" do

      let!(:set) do
        person.set(:age, 2)
      end

      it "sets the provided value" do
        person.age.should == 2
      end

      it "returns the new value" do
        set.should == 2
      end

      it "persists the changes" do
        reloaded.age.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when setting a nil field" do

      let!(:set) do
        person.set(:score, 2)
      end

      it "sets the value to the provided number" do
        person.score.should == 2
      end

      it "returns the new value" do
        set.should == 2
      end

      it "persists the changes" do
        reloaded.score.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["score"].should be_nil
      end
    end

    context "when setting a non existant field" do

      let!(:set) do
        person.set(:high_score, 5)
      end

      it "sets the value to the provided number" do
        person.high_score.should == 5
      end

      it "returns the new value" do
        set.should == 5
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
