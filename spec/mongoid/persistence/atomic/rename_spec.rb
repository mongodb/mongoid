require "spec_helper"

describe Mongoid::Persistence::Atomic::Rename do

  describe "#rename" do

    context "when incrementing a field with a value" do

      let(:person) do
        Person.create(age: 100)
      end

      let!(:rename) do
        person.rename(:age, :years)
      end

      it "removes the old field" do
        person.age.should be_nil
      end

      it "adds the new field" do
        person.years.should eq(100)
      end

      it "returns the value" do
        rename.should eq(100)
      end

      it "resets the old dirty attributes" do
        person.changes["age"].should be_nil
      end

      it "resets the new field dirty attributes" do
        person.changes["years"].should be_nil
      end

      it "persists the changes" do
        person.reload.years.should eq(100)
      end
    end
  end
end
