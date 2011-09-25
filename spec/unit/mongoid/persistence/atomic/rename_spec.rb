require "spec_helper"

describe Mongoid::Persistence::Atomic::Rename do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  after do
    person.unstub(:collection)
  end

  describe "#rename" do

    context "when incrementing a field with a value" do

      let(:person) do
        Person.new(:age => 100)
      end

      let(:rename) do
        described_class.new(person, :age, :years)
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$rename" => { "age" => "years" } }, { :safe => false }
        )
      end

      let!(:renamed) do
        rename.persist
      end

      it "removes the old field" do
        person.age.should be_nil
      end

      it "adds the new field" do
        person.years.should == 100
      end

      it "returns the value" do
        renamed.should == 100
      end

      it "resets the old dirty attributes" do
        person.changes["age"].should be_nil
      end

      it "resets the new field dirty attributes" do
        person.changes["years"].should be_nil
      end
    end
  end
end
