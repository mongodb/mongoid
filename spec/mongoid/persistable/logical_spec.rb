# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Logical do

  describe "#bit" do

    context "when the document is a root document" do

      shared_examples_for "a logical root document" do

        it "applies and operations" do
          expect(person.age).to eq(12)
        end

        it "applies or operations" do
          expect(person.score).to eq(61)
        end

        it "applies mixed operations" do
          expect(person.inte).to eq(14)
        end

        it "returns self object" do
          expect(bit).to eq(person)
        end

        it "resets dirty changes" do
          expect(person).to_not be_changed
        end

        it "persists and operations" do
          expect(person.reload.age).to eq(12)
        end

        it "persists or operations" do
          expect(person.reload.score).to eq(61)
        end

        it "persists mixed operations" do
          expect(person.reload.inte).to eq(14)
        end
      end

      let(:person) do
        Person.create!(age: 60, score: 60, inte: 60)
      end

      context "when provided string fields" do

        let!(:bit) do
          person.bit(
            "age" => { "and" => 13 },
            "score" => { "or" => 13 },
            "inte" => { "and" => 13, "or" => 10 }
          )
        end

        it_behaves_like "a logical root document"
      end

      context "when provided symbol fields" do

        let!(:bit) do
          person.bit(
            age: { and: 13 }, score: { or: 13 }, inte: { and: 13, or: 10 }
          )
        end

        it_behaves_like "a logical root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a logical embedded document" do

        it "applies and operations" do
          expect(address.number).to eq(12)
        end

        it "applies or operations" do
          expect(address.no).to eq(61)
        end

        it "applies mixed operations" do
          expect(address.house).to eq(14)
        end

        it "returns the self object" do
          expect(bit).to eq(address)
        end

        it "resets dirty changes" do
          expect(address).to_not be_changed
        end

        it "persists and operations" do
          expect(address.reload.number).to eq(12)
        end

        it "persists or operations" do
          expect(address.reload.no).to eq(61)
        end

        it "persists mixed operations" do
          expect(address.reload.house).to eq(14)
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "t", number: 60, no: 60, house: 60)
      end

      context "when provided string fields" do

        let!(:bit) do
          address.bit(
            "number" => { "and" => 13 },
            "no" => { "or" => 13 },
            "house" => { "and" => 13, "or" => 10 }
          )
        end

        it_behaves_like "a logical embedded document"
      end

      context "when provided symbol fields" do

        let!(:bit) do
          address.bit(
            number: { and: 13 }, no: { or: 13 }, house: { and: 13, or: 10 }
          )
        end

        it_behaves_like "a logical embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(age: 10, score: 100)
      end

      it "marks a dirty change for the modified fields" do
        person.atomically do
          person.bit age: { and: 6 }, score: { or: 122 }
          expect(person.changes).to eq({"age" => [10, 2], "score" => [100, 126]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(age: 10, score: 100)
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "age" => 1, "score" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.bit(age: { and: 6 }, score: { or: 122 })
          expect(person.age).to eq(2)
          expect(person.score).to eq(126)
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
            person.bit(age: { and: 6 }, score: { or: 122 })
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
