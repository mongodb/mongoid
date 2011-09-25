require "spec_helper"

describe Mongoid::Persistence::Atomic::Push do

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
        Person.new(:aliases => [ "007" ])
      end

      let(:push) do
        described_class.new(person, :aliases, "Bond")
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$push" => { "aliases" => "Bond" } }, { :safe => false }
        )
      end

      let!(:pushed) do
        push.persist
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "007", "Bond" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns the new array value" do
        pushed.should == [ "007", "Bond" ]
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      let(:push) do
        described_class.new(person, :aliases, "Bond")
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector, { "$push" => { "aliases" => "Bond" } }, { :safe => false }
        )
      end

      let!(:pushed) do
        push.persist
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "Bond" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns the new array value" do
        pushed.should == [ "Bond" ]
      end
    end
  end
end
