require "spec_helper"

describe Mongoid::Persistence::Atomic::PushAll do

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

      let(:push_all) do
        described_class.new(person, :aliases, [ "Bond", "James" ])
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector,
          { "$pushAll" => { "aliases" => [ "Bond", "James" ] } }, { :safe => false }
        )
      end

      let!(:pushed) do
        push_all.persist
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "007", "Bond", "James" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns the new array value" do
        pushed.should == [ "007", "Bond", "James" ]
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      let(:push_all) do
        described_class.new(person, :aliases, [ "Bond", "James" ])
      end

      before do
        collection.expects(:update).with(
          person.atomic_selector,
          { "$pushAll" => { "aliases" => [ "Bond", "James" ] } }, { :safe => false }
        )
      end

      let!(:pushed) do
        push_all.persist
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "Bond", "James" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns the new array value" do
        pushed.should == [ "Bond", "James" ]
      end
    end
  end
end
