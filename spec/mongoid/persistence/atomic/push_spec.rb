require "spec_helper"

describe Mongoid::Persistence::Atomic::Push do

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.create(aliases: [ "007" ])
      end

      let!(:pushed) do
        person.push(:aliases, "Bond")
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        expect(person.aliases).to eq([ "007", "Bond" ])
      end

      it "persists the data" do
        expect(reloaded.aliases).to eq([ "007", "Bond" ])
      end

      it "removes the field from the dirty attributes" do
        expect(person.changes["aliases"]).to be_nil
      end

      it "resets the document dirty flag" do
        expect(person).to_not be_changed
      end

      it "returns the new array value" do
        expect(pushed).to eq([ "007", "Bond" ])
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create
      end

      let!(:pushed) do
        person.push(:aliases, "Bond")
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        expect(person.aliases).to eq([ "Bond" ])
      end

      it "persists the data" do
        expect(reloaded.aliases).to eq([ "Bond" ])
      end

      it "removes the field from the dirty attributes" do
        expect(person.changes["aliases"]).to be_nil
      end

      it "resets the document dirty flag" do
        expect(person).to_not be_changed
      end

      it "returns the new array value" do
        expect(pushed).to eq([ "Bond" ])
      end
    end
  end
end
