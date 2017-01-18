require "spec_helper"

describe Mongoid::Persistable::Pushable do

  describe "#add_to_set" do

    context "when the document is a root document" do

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
        Person.create(aliases: [ 1, 2 ], array: [ 4, 5 ])
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
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "t", services: [ 1 ], a: [ 4, 5 ])
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
        Person.create(aliases: [ 1, 2, 3 ], array: [ 4, 5, 6 ])
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
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "t", services: [ 1 ], a: [ 4, 5 ])
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
  end
end
