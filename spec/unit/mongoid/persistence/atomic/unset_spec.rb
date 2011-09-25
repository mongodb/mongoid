require "spec_helper"

describe Mongoid::Persistence::Atomic::Unset do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  after do
    person.unstub(:collection)
  end

  describe "#persist" do

    context "when unsetting a field" do

      let(:person) do
        Person.new(:age => 100)
      end

      let(:unset) do
        described_class.new(person, :age, 1)
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$unset" => { "age" => 1 } }, { :safe => false }
        )
      end

      let!(:removed) do
        unset.persist
      end

      it "removes the field" do
        person.age.should be_nil
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end
  end
end
