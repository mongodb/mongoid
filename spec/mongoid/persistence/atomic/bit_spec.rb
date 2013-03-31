require "spec_helper"

describe Mongoid::Persistence::Atomic::Bit do

  describe "#bit" do

    let(:person) do
      Person.create(age: 60)
    end

    let(:reloaded) do
      person.reload
    end

    context "when performing a bitwise and" do

      let!(:bit) do
        person.bit(:age, { and: 13 })
      end

      it "performs the bitwise operation" do
        expect(person.age).to eq(12)
      end

      it "returns the new value" do
        expect(bit).to eq(12)
      end

      it "persists the changes" do
        expect(reloaded.age).to eq(12)
      end

      it "resets the dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end
    end

    context "when performing a bitwise or" do

      let!(:bit) do
        person.bit(:age, { or: 13 })
      end

      it "performs the bitwise operation" do
        expect(person.age).to eq(61)
      end

      it "returns the new value" do
        expect(bit).to eq(61)
      end

      it "persists the changes" do
        expect(reloaded.age).to eq(61)
      end

      it "resets the dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end
    end

    context "when chaining bitwise operations" do

      let(:hash) do
        { and: 13, or: 10 }
      end

      let!(:bit) do
        person.bit(:age, hash)
      end

      it "performs the bitwise operation" do
        expect(person.age).to eq(14)
      end

      it "returns the new value" do
        expect(bit).to eq(14)
      end

      it "persists the changes" do
        expect(reloaded.age).to eq(14)
      end

      it "resets the dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end
    end
  end
end
