# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Persistable::Multipliable do

  describe "#mul" do

    context "when the document is a root document" do

      shared_examples_for "a multipliable root document" do

        it "multiplies a positive value" do
          expect(person.age).to eq(50)
        end

        it "multiplies a negative value" do
          expect(person.score).to eq(-500)
        end

        it "multiplies a nonexistent value" do
          expect(person.inte).to eq(0)
        end

        it "returns the self document" do
          expect(op).to eq(person)
        end

        it "persists a positive mul" do
          expect(person.reload.age).to eq(50)
        end

        it "persists a negative mul" do
          expect(person.reload.score).to eq(-500)
        end

        it "persists a nonexistent mul" do
          expect(person.reload.inte).to eq(0)
        end

        it "clears out dirty changes" do
          expect(person).to_not be_changed
        end
      end

      let(:person) do
        Person.create!(age: 10, score: 100)
      end

      context "when providing string fields" do

        let!(:op) do
          person.mul("age" => 5, "score" => -5, "inte" => 30)
        end

        it_behaves_like "a multipliable root document"
      end

      context "when providing symbol fields" do

        let!(:op) do
          person.mul(age: 5, score: -5, inte: 30)
        end

        it_behaves_like "a multipliable root document"
      end

      context "when providing big decimal values" do

        let(:positive) do
          BigDecimal("5.0")
        end

        let(:negative) do
          BigDecimal("-5.0")
        end

        let(:dynamic) do
          BigDecimal("30.0")
        end

        let!(:op) do
          person.mul(age: positive, score: negative, inte: dynamic)
        end

        it_behaves_like "a multipliable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a multipliable embedded document" do

        it "multiplies a positive value" do
          expect(address.number).to eq(50)
        end

        it "multiplies a negative value" do
          expect(address.no).to eq(-500)
        end

        it "multiplies a nonexistent value" do
          expect(address.house).to eq(0)
        end

        it "returns the self document" do
          expect(op).to eq(address)
        end

        it "persists a positive mul" do
          expect(address.reload.number).to eq(50)
        end

        it "persists a negative mul" do
          expect(address.reload.no).to eq(-500)
        end

        it "persists a nonexistent mul" do
          expect(address.reload.house).to eq(0)
        end

        it "clears out dirty changes" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "test", number: 10, no: 100)
      end

      context "when providing string fields" do

        let!(:op) do
          address.mul("number" => 5, "no" => -5, "house" => 30)
        end

        it_behaves_like "a multipliable embedded document"
      end

      context "when providing symbol fields" do

        let!(:op) do
          address.mul(number: 5, no: -5, house: 30)
        end

        it_behaves_like "a multipliable embedded document"
      end

      context "when providing big decimal values" do

        let(:positive) do
          BigDecimal("5.0")
        end

        let(:negative) do
          BigDecimal("-5.0")
        end

        let(:dynamic) do
          BigDecimal("30.0")
        end

        let!(:op) do
          address.mul(number: positive, no: negative, house: dynamic)
        end

        it_behaves_like "a multipliable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(age: 10, score: 100)
      end

      it "marks a dirty change for the multiplied fields" do
        person.atomically do
          person.mul age: 15, score: 2
          expect(person.changes).to eq({"age" => [10, 150], "score" => [100, 200]})
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
          person.mul(age: 15, score: 2)
          expect(person.age).to eq(150)
          expect(person.score).to eq(200)
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
            person.mul(age: 15, score: 2)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
