require "spec_helper"

describe Mongoid::Persistence::Atomic::Inc do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  after do
    person.unstub(:collection)
  end

  describe "#inc" do

    let(:reloaded) do
      person.reload
    end

    context "when incrementing a field with a value" do

      let(:person) do
        Person.new(:age => 100)
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$inc" => { "age" => 2 } }, { :safe => false }
        )
      end

      let!(:inced) do
        person.inc(:age, 2)
      end

      it "increments by the provided value" do
        person.age.should == 102
      end

      it "returns the new value" do
        inced.should == 102
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when incrementing a nil field" do

      let(:person) do
        Person.new
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$inc" => { "score" => 2 } }, { :safe => false }
        )
      end

      let!(:inced) do
        person.inc(:score, 2)
      end

      it "sets the value to the provided number" do
        person.score.should == 2
      end

      it "returns the new value" do
        inced.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["score"].should be_nil
      end
    end

    context "when incrementing a non existant field" do

      let(:person) do
        Person.new
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$inc" => { "high_score" => 5 } }, { :safe => false }
        )
      end

      let!(:inced) do
        person.inc(:high_score, 5)
      end

      it "sets the value to the provided number" do
        person.high_score.should == 5
      end

      it "returns the new value" do
        inced.should == 5
      end

      it "resets the dirty attributes" do
        person.changes["high_score"].should be_nil
      end
    end
  end
end
