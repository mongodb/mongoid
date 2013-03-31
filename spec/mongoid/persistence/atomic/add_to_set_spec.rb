require "spec_helper"

describe Mongoid::Persistence::Atomic::AddToSet do

  describe "#persist" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      context "when adding a single value" do

        let!(:added) do
          person.add_to_set(:aliases, "Bond")
        end

        it "adds the value onto the array" do
          expect(person.aliases).to eq([ "Bond" ])
        end

        it "does not reset the dirty flagging" do
          expect(person.changes["aliases"]).to eq([nil, ["Bond"]])
        end

        it "returns the new array value" do
          expect(added).to eq([ "Bond" ])
        end
      end

      context "when adding multiple values" do

        let!(:added) do
          person.add_to_set(:aliases, [ "Bond", "James" ])
        end

        it "adds the value onto the array" do
          expect(person.aliases).to eq([ "Bond", "James" ])
        end

        it "does not reset the dirty flagging" do
          expect(person.changes["aliases"]).to eq([nil, ["Bond", "James"]])
        end

        it "returns the new array value" do
          expect(added).to eq([ "Bond", "James" ])
        end
      end
    end

    context "when the field exists" do

      context "when the value is unique" do

        let(:person) do
          Person.create(aliases: [ "007" ])
        end

        context "when adding a single value" do

          let!(:added) do
            person.add_to_set(:aliases, "Bond")
          end

          let(:reloaded) do
            person.reload
          end

          it "adds the value onto the array" do
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
            expect(added).to eq([ "007", "Bond" ])
          end
        end

        context "when adding a multiple values" do

          let!(:added) do
            person.add_to_set(:aliases, [ "Bond", "James" ])
          end

          let(:reloaded) do
            person.reload
          end

          it "adds the value onto the array" do
            expect(person.aliases).to eq([ "007", "Bond", "James" ])
          end

          it "persists the data" do
            expect(reloaded.aliases).to eq([ "007", "Bond", "James" ])
          end

          it "removes the field from the dirty attributes" do
            expect(person.changes["aliases"]).to be_nil
          end

          it "resets the document dirty flag" do
            expect(person).to_not be_changed
          end

          it "returns the new array value" do
            expect(added).to eq([ "007", "Bond", "James" ])
          end
        end
      end

      context "when the value is not unique" do

        let(:person) do
          Person.create(aliases: [ "Bond" ])
        end

        context "when adding a single value" do

          let!(:added) do
            person.add_to_set(:aliases, "Bond")
          end

          let(:reloaded) do
            person.reload
          end

          it "does not add the value" do
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

          it "returns the array value" do
            expect(added).to eq([ "Bond" ])
          end
        end

        context "when adding multiple values" do

          let!(:added) do
            person.add_to_set(:aliases, [ "Bond", "James" ])
          end

          let(:reloaded) do
            person.reload
          end

          it "does not add the duplicate value" do
            expect(person.aliases).to eq([ "Bond", "James" ])
          end

          it "persists the data" do
            expect(reloaded.aliases).to eq([ "Bond", "James" ])
          end

          it "removes the field from the dirty attributes" do
            expect(person.changes["aliases"]).to be_nil
          end

          it "resets the document dirty flag" do
            expect(person).to_not be_changed
          end

          it "returns the array value" do
            expect(added).to eq([ "Bond", "James" ])
          end
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create
      end

      context "when adding a single value" do

        let!(:added) do
          person.add_to_set(:aliases, "Bond")
        end

        let(:reloaded) do
          person.reload
        end

        it "adds the value onto the array" do
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
          expect(added).to eq([ "Bond" ])
        end
      end

      context "when adding multiple values" do

        let!(:added) do
          person.add_to_set(:aliases, [ "Bond", "James" ])
        end

        let(:reloaded) do
          person.reload
        end

        it "adds the value onto the array" do
          expect(person.aliases).to eq([ "Bond", "James" ])
        end

        it "persists the data" do
          expect(reloaded.aliases).to eq([ "Bond", "James" ])
        end

        it "removes the field from the dirty attributes" do
          expect(person.changes["aliases"]).to be_nil
        end

        it "resets the document dirty flag" do
          expect(person).to_not be_changed
        end

        it "returns the new array value" do
          expect(added).to eq([ "Bond", "James" ])
        end
      end
    end
  end
end
