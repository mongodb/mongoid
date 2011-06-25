require "spec_helper"

describe Mongoid::Persistence::Atomic::Pull do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.new(:aliases => [ "007", "008", "009" ])
      end

      let(:pull) do
        described_class.new(person, :aliases, "008")
      end

      before do
        person.new_record = false
        collection.expects(:update).with(
          person._selector,
          { "$pull" => { :aliases => "008" } },
          { :safe => false }
        )
      end

      let!(:pulled) do
        pull.persist
      end

      it "removes the values from the array" do
        person.aliases.should == [ "007", "009" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        pulled.should == [ "007", "009" ]
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      let(:pull) do
        described_class.new(person, :aliases, "Bond")
      end

      let!(:pulled) do
        pull.persist
      end

      it "does not initialize the field" do
        person.aliases.should be_nil
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns nil" do
        pulled.should be_nil
      end
    end
  end
end
