require "spec_helper"

describe Mongoid::Persistence::Atomic::PullAll do

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

    context "when the field exists" do

      let(:person) do
        Person.new(:aliases => [ "007", "008", "009" ])
      end

      let(:pull_all) do
        described_class.new(person, :aliases, [ "008", "009" ])
      end

      before do
        person.new_record = false
        collection.expects(:update).with(
          person.atomic_selector,
          { "$pullAll" => { "aliases" => [ "008", "009" ] } },
          { :safe => false }
        )
      end

      let!(:added) do
        pull_all.persist
      end

      it "removes the values from the array" do
        person.aliases.should == [ "007" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns the new array value" do
        added.should == [ "007" ]
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      let(:pull_all) do
        described_class.new(person, :aliases, [ "Bond" ])
      end

      let!(:added) do
        pull_all.persist
      end

      it "does not initialize the field" do
        person.aliases.should be_nil
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns nil" do
        added.should be_nil
      end
    end
  end
end
