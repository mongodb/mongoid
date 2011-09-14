require "spec_helper"

describe Mongoid::Persistence::Atomic::Pop do

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

      context "when popping the first element" do

        let(:pop) do
          described_class.new(person, :aliases, -1)
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$pop" => { "aliases" => -1 } },
            { :safe => false }
          )
        end

        let!(:popped) do
          pop.persist
        end

        it "removes the first value from the array" do
          person.aliases.should == [ "008", "009" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "returns the new array value" do
          popped.should == [ "008", "009" ]
        end
      end

      context "when popping the last element" do

        let(:pop) do
          described_class.new(person, :aliases, 1)
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$pop" => { "aliases" => 1 } },
            { :safe => false }
          )
        end

        let!(:popped) do
          pop.persist
        end

        it "removes the first value from the array" do
          person.aliases.should == [ "007", "008" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "returns the new array value" do
          popped.should == [ "007", "008" ]
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      let(:pop) do
        described_class.new(person, :aliases, 1)
      end

      let!(:popped) do
        pop.persist
      end

      it "does not initialize the field" do
        person.aliases.should be_nil
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "returns nil" do
        popped.should be_nil
      end
    end
  end
end
