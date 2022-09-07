# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Pullable do

  describe "#pull" do

    context "when the document is a root document" do

      shared_examples_for "a pullable root document" do

        it "pulls the first value" do
          expect(person.aliases).to eq([ 2, 3 ])
        end

        it "pulls the last value" do
          expect(person.array).to eq([ 4, 6 ])
        end

        it "returns self object" do
          expect(pull).to eq(person)
        end

        it "resets dirty changes" do
          expect(person).to_not be_changed
        end

        it "persists the first pull" do
          expect(person.reload.aliases).to eq([ 2, 3 ])
        end

        it "persists the last pull" do
          expect(person.reload.array).to eq([ 4, 6 ])
        end
      end

      let(:person) do
        Person.create!(aliases: [ 1, 1, 2, 3 ], array: [ 4, 5, 6 ])
      end

      context "when providing string keys" do

        let!(:pull) do
          person.pull("aliases" => 1, "array" => 5, "test_array" => 2)
        end

        it_behaves_like "a pullable root document"
      end

      context "when providing symbol keys" do

        let!(:pull) do
          person.pull(aliases: 1, array: 5)
        end

        it_behaves_like "a pullable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a pullable embedded document" do

        it "pulls the first value" do
          expect(address.services).to eq([ 2, 3 ])
        end

        it "pulls the last value" do
          expect(address.a).to eq([ 4, 6 ])
        end

        it "returns self object" do
          expect(pull).to eq(address)
        end

        it "resets dirty changes" do
          expect(address).to_not be_changed
        end

        it "persists the first pull" do
          expect(address.reload.services).to eq([ 2, 3 ])
        end

        it "persists the last pull" do
          expect(address.reload.a).to eq([ 4, 6 ])
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t", services: [ 1, 2, 3 ], a: [ 4, 5, 6 ])
      end

      context "when providing string keys" do

        let!(:pull) do
          address.pull("services" => 1, "a" => 5)
        end

        it_behaves_like "a pullable embedded document"
      end

      context "when providing symbol keys" do

        let!(:pull) do
          address.pull(services: 1, a: 5)
        end

        it_behaves_like "a pullable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(test_array: [ 1, 1, 2, 3 ])
      end

      it "marks a dirty change for the pulled fields" do
        person.atomically do
          person.pull test_array: 1
          expect(person.changes).to eq({"test_array" => [[ 1, 1, 2, 3 ], [ 2, 3 ]]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(test_array: [ 1, 1, 2, 3 ])
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.pull(test_array: 1)
          expect(person.test_array).to eq([ 2, 3 ])
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
            person.pull(test_array: 1)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end

  describe "#pull_all" do

    context "when the document is the root document" do

      shared_examples_for "a multi-pullable root document" do

        it "pulls the first value" do
          expect(person.aliases).to eq([ 3 ])
        end

        it "pulls the last value" do
          expect(person.array).to eq([ 4 ])
        end

        it "returns self object" do
          expect(pull_all).to eq(person)
        end

        it "resets dirty changes" do
          expect(person).to_not be_changed
        end

        it "persists the first pull" do
          expect(person.reload.aliases).to eq([ 3 ])
        end

        it "persists the last pull" do
          expect(person.reload.array).to eq([ 4 ])
        end
      end

      let(:person) do
        Person.create!(aliases: [ 1, 1, 2, 3 ], array: [ 4, 5, 6 ])
      end

      context "when providing string keys" do

        let!(:pull_all) do
          person.pull_all(
            "aliases" => [ 1, 2 ], "array" => [ 5, 6 ], "test_array" => [ 1 ]
          )
        end

        it_behaves_like "a multi-pullable root document"
      end

      context "when providing symbol keys" do

        let!(:pull_all) do
          person.pull_all(aliases: [ 1, 2 ], array: [ 5, 6 ])
        end

        it_behaves_like "a multi-pullable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a multi-pullable embedded document" do

        it "pulls the first value" do
          expect(address.services).to eq([ 3 ])
        end

        it "pulls the last value" do
          expect(address.a).to eq([ 4 ])
        end

        it "returns self object" do
          expect(pull_all).to eq(address)
        end

        it "resets dirty changes" do
          expect(address).to_not be_changed
        end

        it "persists the first pull" do
          expect(address.reload.services).to eq([ 3 ])
        end

        it "persists the last pull" do
          expect(address.reload.a).to eq([ 4 ])
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t", services: [ 1, 2, 3 ], a: [ 4, 5, 6 ])
      end

      context "when providing string keys" do

        let!(:pull_all) do
          address.pull_all("services" => [ 1, 2 ], "a" => [ 5, 6 ])
        end

        it_behaves_like "a multi-pullable embedded document"
      end

      context "when providing symbol keys" do

        let!(:pull_all) do
          address.pull_all(services: [ 1, 2 ], a: [ 5, 6 ])
        end

        it_behaves_like "a multi-pullable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(test_array: [ 1, 1, 2, 3, 4 ])
      end

      it "marks a dirty change for the pulled fields" do
        person.atomically do
          person.pull_all test_array: [ 1, 2 ]
          expect(person.changes).to eq({"test_array" => [[ 1, 1, 2, 3, 4 ], [ 3, 4 ]]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(test_array: [ 1, 1, 2, 3, 4 ])
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.pull_all(test_array: [ 1, 2 ])
          expect(person.test_array).to eq([ 3, 4 ])
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
            person.pull_all(test_array: [ 1, 2 ])
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
