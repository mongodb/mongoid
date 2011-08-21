require "spec_helper"

describe Mongoid::Persistence::Atomic::Bit do

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

    context "when the field does not exist" do

      let(:person) do
        Person.new(:age => nil)
      end

      let(:bit) do
        described_class.new(person, :age, { :and => 13 })
      end

      let!(:result) do
        bit.persist
      end

      it "does not modify the field" do
        person.age.should be_nil
      end

      it "returns nil" do
        result.should be_nil
      end
    end

    context "when the field exists" do

      context "when performing a bitwise and" do

        let(:person) do
          Person.new(:age => 60)
        end

        let(:bit) do
          described_class.new(person, :age, { :and => 13 })
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$bit" => { "age" => { :and => 13 } } },
            :safe => false
          )
        end

        let!(:result) do
          bit.persist
        end

        it "modifies the field" do
          person.age.should == 12
        end

        it "removes the field from the dirty attributes" do
          person.changes["age"].should be_nil
        end

        it "returns the new field value" do
          result.should == 12
        end
      end

      context "when performing a bitwise or" do

        let(:person) do
          Person.new(:age => 60)
        end

        let(:bit) do
          described_class.new(person, :age, { :or => 13 })
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$bit" => { "age" => { :or => 13 } } },
            :safe => false
          )
        end

        let!(:result) do
          bit.persist
        end

        it "modifies the field" do
          person.age.should == 61
        end

        it "removes the field from the dirty attributes" do
          person.changes["age"].should be_nil
        end

        it "returns the new field value" do
          result.should == 61
        end
      end

      context "when chaining bitwise operations" do

        let(:person) do
          Person.new(:age => 60)
        end

        let(:hash) do
          BSON::OrderedHash.new.tap do |h|
            h[:and] = 13
            h[:or] = 10
          end
        end

        let(:bit) do
          described_class.new(person, :age, hash)
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$bit" => { "age" => { :and => 13, :or => 10 } } },
            :safe => false
          )
        end

        let!(:result) do
          bit.persist
        end

        it "modifies the field" do
          person.age.should == 14
        end

        it "removes the field from the dirty attributes" do
          person.changes["age"].should be_nil
        end

        it "returns the new field value" do
          result.should == 14
        end
      end
    end
  end
end
