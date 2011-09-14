require "spec_helper"

describe Mongoid::Persistence::Atomic::Sets do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  after do
    person.unstub(:collection)
  end

  describe "#set" do

    let(:reloaded) do
      person.reload
    end

    context "when setting a field with a value" do

      let(:person) do
        Person.new(:age => 100)
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$set" => { "age" => 2 } }, { :safe => false }
        )
      end

      let!(:set) do
        person.set(:age, 2)
      end

      it "sets the provided value" do
        person.age.should == 2
      end

      it "returns the new value" do
        set.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when setting a nil field" do

      let(:person) do
        Person.new
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$set" => { "score" => 2 } }, { :safe => false }
        )
      end

      let!(:set) do
        person.set(:score, 2)
      end

      it "sets the value to the provided number" do
        person.score.should == 2
      end

      it "returns the new value" do
        set.should == 2
      end

      it "resets the dirty attributes" do
        person.changes["score"].should be_nil
      end
    end

    context "when setting a non existant field" do

      let(:person) do
        Person.new
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$set" => { "high_score" => 5 } }, { :safe => false }
        )
      end

      let!(:set) do
        person.set(:high_score, 5)
      end

      it "sets the value to the provided number" do
        person.high_score.should == 5
      end

      it "returns the new value" do
        set.should == 5
      end

      it "resets the dirty attributes" do
        person.changes["high_score"].should be_nil
      end
    end
  end
end
