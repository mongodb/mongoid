require "spec_helper"

describe Mongoid::Persistence::Atomic::Rename do

  before do
    Person.delete_all
  end

  describe "#rename" do

    context "when incrementing a field with a value" do

      let(:person) do
        Person.create(:ssn => "443-22-1111", :age => 100)
      end

      let!(:rename) do
        person.rename(:age, :years)
      end

      it "removes the old field" do
        person.age.should be_nil
      end

      it "adds the new field" do
        person.years.should == 100
      end

      it "returns the value" do
        rename.should == 100
      end

      it "resets the old dirty attributes" do
        person.changes["age"].should be_nil
      end

      it "resets the new field dirty attributes" do
        person.changes["years"].should be_nil
      end

      it "persists the changes" do
        person.reload.years.should == 100
      end
    end
  end
end
