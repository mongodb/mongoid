require "spec_helper"

describe Mongoid::Persistable::Atomic::Pop do

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.create(aliases: [ "007", "008", "009" ])
      end

      context "when popping the last element" do

        let!(:popped) do
          person.pop(:aliases, 1)
        end

        let(:reloaded) do
          person.reload
        end

        it "pops the value from the array" do
          expect(person.aliases).to eq([ "007", "008" ])
        end

        it "persists the data" do
          expect(reloaded.aliases).to eq([ "007", "008" ])
        end

        it "removes the field from the dirty attributes" do
          expect(person.changes["aliases"]).to be_nil
        end

        it "resets the document dirty flag" do
          expect(person).to_not be_changed
        end

        it "returns the new array value" do
          expect(popped).to eq([ "007", "008" ])
        end
      end

      context "when popping the first element" do

        let!(:popped) do
          person.pop(:aliases, -1)
        end

        let(:reloaded) do
          person.reload
        end

        it "pops the value from the array" do
          expect(person.aliases).to eq([ "008", "009" ])
        end

        it "persists the data" do
          expect(reloaded.aliases).to eq([ "008", "009" ])
        end

        it "removes the field from the dirty attributes" do
          expect(person.changes["aliases"]).to be_nil
        end

        it "resets the document dirty flag" do
          expect(person).to_not be_changed
        end

        it "returns the new array value" do
          expect(popped).to eq([ "008", "009" ])
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create
      end

      let!(:popped) do
        person.pop(:aliases, 1)
      end

      let(:reloaded) do
        person.reload
      end

      it "does not modify the field" do
        expect(person.aliases).to be_nil
      end

      it "persists no data" do
        expect(reloaded.aliases).to be_nil
      end

      it "removes the field from the dirty attributes" do
        expect(person.changes["aliases"]).to be_nil
      end

      it "resets the document dirty flag" do
        expect(person).to_not be_changed
      end

      it "returns nil" do
        expect(popped).to be_nil
      end
    end
  end
end
