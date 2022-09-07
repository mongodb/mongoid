# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Unsettable do

  describe "#unset" do

    context "when the document is a root document" do

      shared_examples_for "an unsettable root document" do

        it "unsets the first field" do
          expect(person.title).to be_nil
        end

        it "unsets the second field" do
          expect(person.age).to be_nil
        end

        it "returns self object" do
          expect(unset).to eq(person)
        end

        it "persists the first unset" do
          expect(person.reload.title).to be_nil
        end

        it "persists the last_unset" do
          expect(person.reload.age).to eq(100)
        end

        it "clears out dirty changes for the fields" do
          expect(person).to_not be_changed
        end
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      let(:person) do
        Person.create!(title: "test", age: 30, dob: date)
      end

      context "when provided a splat of symbols" do

        let!(:unset) do
          person.unset(:title, :age)
        end

        it_behaves_like "an unsettable root document"
      end

      context "when provided a splat of strings" do

        let!(:unset) do
          person.unset("title", "age")
        end

        it_behaves_like "an unsettable root document"
      end

      context "when provided an array of symbols" do

        let!(:unset) do
          person.unset([ :title, :age ])
        end

        it_behaves_like "an unsettable root document"
      end

      context "when provided an array of strings" do

        let!(:unset) do
          person.unset([ "title", "age" ])
        end

        it_behaves_like "an unsettable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "an unsettable embedded document" do

        it "unsets the first field" do
          expect(address.number).to be_nil
        end

        it "unsets the second field" do
          expect(address.city).to be_nil
        end

        it "returns self object" do
          expect(unset).to eq(address)
        end

        it "persists the first unset" do
          expect(address.reload.number).to be_nil
        end

        it "persists the last_unset" do
          expect(address.reload.city).to be_nil
        end

        it "clears out dirty changes for the fields" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "kreuzberg", number: 40, city: "Berlin")
      end

      context "when provided a splat of symbols" do

        let!(:unset) do
          address.unset(:number, :city)
        end

        it_behaves_like "an unsettable embedded document"
      end

      context "when provided a splat of strings" do

        let!(:unset) do
          address.unset("number", "city")
        end

        it_behaves_like "an unsettable embedded document"
      end

      context "when provided an array of symbols" do

        let!(:unset) do
          address.unset([ :number, :city ])
        end

        it_behaves_like "an unsettable embedded document"
      end

      context "when provided an array of strings" do

        let!(:unset) do
          address.unset([ "number", "city" ])
        end

        it_behaves_like "an unsettable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(title: "sir", age: 30)
      end

      it "marks a dirty change for the unset fields" do
        person.atomically do
          person.unset :title
          expect(person.changes).to eq({"title" => ["sir", nil]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(title: "sir", age: 30)
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "title" => 1, "age" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.unset(:title)
          expect(person.title).to be nil
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
            person.unset(:title)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
