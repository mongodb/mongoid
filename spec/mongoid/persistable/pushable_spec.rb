# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Pushable do

  describe "#add_to_set" do

    context "when the document is a top level document" do

      shared_examples_for "a unique pushable root document" do

        it "adds single values" do
          expect(person.aliases).to eq([ 1, 2, 4 ])
        end

        it "does not add duplicate values" do
          expect(person.array).to eq([ 4, 5 ])
        end

        it "sets absent values" do
          expect(person.test_array).to eq([ 1 ])
        end

        it "returns self objet" do
          expect(add).to eq(person)
        end

        it "resets the dirty changes" do
          expect(person).to_not be_changed
        end

        it "persists single adds" do
          expect(person.reload.aliases).to eq([ 1, 2, 4 ])
        end

        it "persists absent values" do
          expect(person.reload.test_array).to eq([ 1 ])
        end

        it "flattens only 1 level" do
          expect(person.reload.arrays).to eq([[ 7, 8 ]])
        end
      end

      let(:person) do
        Person.create!(aliases: [ 1, 2 ], array: [ 4, 5 ])
      end

      context "when provided string fields" do

        let!(:add) do
          person.add_to_set("aliases" => 4, "array" => [4, 5], "test_array" => 1, "arrays" => [[ 7, 8 ]])
        end

        it_behaves_like "a unique pushable root document"
      end

      context "when provided symbol fields" do

        let!(:add) do
          person.add_to_set(aliases: 4, array: [4, 5], test_array: 1, arrays: [[ 7, 8 ]])
        end

        it_behaves_like "a unique pushable root document"
      end

      context 'when the host model is not saved' do
        context 'when attribute exists' do
          let(:person) do
            Person.new(aliases: [2])
          end

          it 'records the change' do
            person.add_to_set({aliases: 1})

            expect(person.aliases).to eq([2, 1])
          end
        end

        context 'when attribute does not exist' do
          let(:person) do
            Person.new
          end

          it 'records the change' do
            person.add_to_set({aliases: 1})

            expect(person.aliases).to eq([1])
          end
        end
      end

      context 'when the host model is loaded from database' do
        context 'when attribute exists' do
          let(:person) do
            Person.create!(aliases: [2])
            person = Person.last
          end

          it 'records the change' do
            person.add_to_set({aliases: 1})

            expect(person.aliases).to eq([2, 1])
          end
        end

        context 'when attribute does not exist' do
          let(:person) do
            Person.create!
            person = Person.last
          end

          it 'records the change' do
            person.add_to_set({aliases: 1})

            expect(person.aliases).to eq([1])
          end
        end
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a unique pushable embedded document" do

        it "adds single values" do
          expect(address.services).to eq([ 1, 4 ])
        end

        it "does not add duplicate values" do
          expect(address.a).to eq([ 4, 5 ])
        end

        it "sets absent values" do
          expect(address.test).to eq([ 1 ])
        end

        it "returns self object" do
          expect(add).to eq(address)
        end

        it "resets the dirty changes" do
          expect(address).to_not be_changed
        end

        it "persists single adds" do
          expect(address.reload.services).to eq([ 1, 4 ])
        end

        it "persists absent values" do
          expect(address.reload.test).to eq([ 1 ])
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t", services: [ 1 ], a: [ 4, 5 ])
      end

      context "when provided string fields" do

        let!(:add) do
          address.add_to_set("services" => 4, "a" => 5, "test" => 1)
        end

        it_behaves_like "a unique pushable embedded document"
      end

      context "when provided symbol fields" do

        let!(:add) do
          address.add_to_set(services: 4, a: 5, test: 1)
        end

        it_behaves_like "a unique pushable embedded document"
      end

      context "when provided an array of objects" do

        before do
          person.add_to_set(array: [{ a: 1}, { b: 2}])
        end

        it 'persists the array of objects' do
          expect(person.reload.array).to eq([{ 'a' => 1}, { 'b' => 2}])
        end
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(test_array: [ 1, 2, 3 ])
      end

      it "marks a dirty change for the modified fields" do
        person.atomically do
          person.add_to_set test_array: [ 1, 4 ]
          expect(person.changes).to eq({"test_array" => [[ 1, 2, 3 ], [ 1, 2, 3, 4 ]]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(test_array: [ 1, 2, 3 ])
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.add_to_set(test_array: [ 1, 4 ])
          expect(person.test_array).to eq([ 1, 2, 3, 4 ])
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
            person.add_to_set(test_array: [ 1, 4 ])
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end

  describe "#push" do

    context "when the document is a root document" do

      shared_examples_for "a pushable root document" do

        it "pushes single values" do
          expect(person.aliases).to eq([ 1, 2, 3, 4 ])
        end

        it "pushes multiple values" do
          expect(person.array).to eq([ 4, 5, 6, 7, 8 ])
        end

        it "sets absent values" do
          expect(person.test_array).to eq([ 1 ])
        end

        it "returns self object" do
          expect(push).to eq(person)
        end

        it "resets the dirty changes" do
          expect(person).to_not be_changed
        end

        it "persists single pushes" do
          expect(person.reload.aliases).to eq([ 1, 2, 3, 4 ])
        end

        it "persists multiple pushes" do
          expect(person.reload.array).to eq([ 4, 5, 6, 7, 8 ])
        end

        it "persists absent values" do
          expect(person.reload.test_array).to eq([ 1 ])
        end

        it "flattens only 1 level" do
          expect(person.reload.arrays).to eq([[ 7, 8 ]])
        end
      end

      let(:person) do
        Person.create!(aliases: [ 1, 2, 3 ], array: [ 4, 5, 6 ])
      end

      context "when provided string fields" do

        let!(:push) do
          person.push("aliases" => 4, "array" => [ 7, 8 ], "test_array" => 1, "arrays" => [[ 7, 8 ]])
        end

        it_behaves_like "a pushable root document"
      end

      context "when provided symbol fields" do

        let!(:push) do
          person.push(aliases: 4, array: [ 7, 8 ], test_array: 1, arrays: [[ 7, 8 ]])
        end

        it_behaves_like "a pushable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a pushable embedded document" do

        it "pushes single values" do
          expect(address.services).to eq([ 1, 4 ])
        end

        it "pushes multiple values" do
          expect(address.a).to eq([ 4, 5, 6, 7 ])
        end

        it "sets absent values" do
          expect(address.test).to eq([ 1 ])
        end

        it "returns self object" do
          expect(push).to eq(address)
        end

        it "resets the dirty changes" do
          expect(address).to_not be_changed
        end

        it "persists single pushes" do
          expect(address.reload.services).to eq([ 1, 4 ])
        end

        it "persists multiple pushes" do
          expect(address.reload.a).to eq([ 4, 5, 6, 7 ])
        end

        it "persists absent values" do
          expect(address.reload.test).to eq([ 1 ])
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t", services: [ 1 ], a: [ 4, 5 ])
      end

      context "when provided string fields" do

        let!(:push) do
          address.push("services" => 4, "a" => [ 6, 7 ], "test" => 1)
        end

        it_behaves_like "a pushable embedded document"
      end

      context "when provided symbol fields" do

        let!(:push) do
          address.push(services: 4, a: [ 6, 7 ], test: 1)
        end

        it_behaves_like "a pushable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(test_array: [ 1, 2, 3 ])
      end

      it "marks a dirty change for the pushed fields" do
        person.atomically do
          person.push test_array: [ 1, 4 ]
          expect(person.changes).to eq({"test_array" => [[ 1, 2, 3 ], [ 1, 2, 3, 1, 4 ]]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(test_array: [ 1, 2, 3 ])
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.push(test_array: [ 1, 4 ])
          expect(person.test_array).to eq([ 1, 2, 3, 1, 4 ])
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
            person.push(test_array: [ 1, 4 ])
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
