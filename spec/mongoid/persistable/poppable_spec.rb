# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Poppable do

  describe "#pop" do

    context "when the document is the root document" do

      shared_examples_for "a poppable root document" do

        it "pops for positive values" do
          expect(person.array).to eq([ 1, 2, 3 ])
        end

        it "shifts for negative values" do
          expect(person.aliases).to eq([ "b" ])
        end

        it "returns the self object" do
          expect(pop).to eq(person)
        end

        it "persists pops" do
          expect(person.reload.array).to eq([ 1, 2, 3 ])
        end

        it "persists shifts" do
          expect(person.reload.aliases).to eq([ "b" ])
        end

        it "clears out dirty changes" do
          expect(person).to_not be_changed
        end
      end

      let(:person) do
        Person.create!(array: [ 1, 2, 3, 4 ], aliases: [ "a", "b" ])
      end

      context "when provided string fields" do

        let!(:pop) do
          person.pop("array" => 1, "aliases" => -1)
        end

        it_behaves_like "a poppable root document"
      end

      context "when provided symbol fields" do

        let!(:pop) do
          person.pop(array: 1, aliases: -1)
        end

        it_behaves_like "a poppable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a poppable embedded document" do

        it "pops for positive values" do
          expect(address.services).to eq([ 1, 2, 3 ])
        end

        it "shifts for negative values" do
          expect(address.aliases).to eq([ "b" ])
        end

        it "returns self object" do
          expect(pop).to eq(address)
        end

        it "persists pops" do
          expect(address.reload.services).to eq([ 1, 2, 3 ])
        end

        it "persists shifts" do
          expect(address.reload.aliases).to eq([ "b" ])
        end

        it "clears out dirty changes" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "test", services: [ 1, 2, 3, 4 ], aliases: [ "a", "b" ])
      end

      context "when provided string fields" do

        let!(:pop) do
          address.pop("services" => 1, "aliases" => -1)
        end

        it_behaves_like "a poppable embedded document"
      end

      context "when provided symbol fields" do

        let!(:pop) do
          address.pop(services: 1, aliases: -1)
        end

        it_behaves_like "a poppable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(test_array: [1, 2, 3])
      end

      it "marks a dirty change for the popped fields" do
        person.atomically do
          person.pop test_array: 1
          expect(person.changes).to eq({"test_array" => [[1, 2, 3], [1, 2]]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(test_array: [1, 2, 3])
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.pop(test_array: 1)
          expect(person.test_array).to eq([ 1, 2 ])
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        before do
          person.readonly!
        end

        it "raises a ReadonlyDocument error" do
          expect(person).to be_readonly
          expect do
            person.pop(test_array: 1)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
