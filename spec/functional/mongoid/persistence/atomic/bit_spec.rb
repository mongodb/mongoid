require "spec_helper"

describe Mongoid::Persistence::Atomic::Bit do

  before do
    Person.delete_all
  end

  describe "#bit" do

    let(:person) do
      Person.create(:ssn => "777-66-1011", :age => 60)
    end

    let(:reloaded) do
      person.reload
    end

    context "when performing a bitwise and" do

      let!(:bit) do
        person.bit(:age, { :and => 13 })
      end

      it "performs the bitwise operation" do
        person.age.should == 12
      end

      it "returns the new value" do
        bit.should == 12
      end

      it "persists the changes" do
        reloaded.age.should == 12
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when performing a bitwise or" do

      let!(:bit) do
        person.bit(:age, { :or => 13 })
      end

      it "performs the bitwise operation" do
        person.age.should == 61
      end

      it "returns the new value" do
        bit.should == 61
      end

      it "persists the changes" do
        reloaded.age.should == 61
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end

    context "when chaining bitwise operations" do

      let(:hash) do
        BSON::OrderedHash.new.tap do |h|
          h[:and] = 13
          h[:or] = 10
        end
      end

      let!(:bit) do
        person.bit(:age, hash)
      end

      it "performs the bitwise operation" do
        person.age.should == 14
      end

      it "returns the new value" do
        bit.should == 14
      end

      it "persists the changes" do
        reloaded.age.should == 14
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end
    end
  end
end
