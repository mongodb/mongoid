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
        expect(person.age).to be_nil
      end

      it "adds the new field" do
        expect(person.years).to eq(100)
      end

      it "returns the value" do
        expect(rename).to eq(100)
      end

      it "resets the old dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end

      it "resets the new field dirty attributes" do
        expect(person.changes["years"]).to be_nil
      end

      it "persists the changes" do
        expect(person.reload.years).to eq(100)
      end
    end
  end
end
