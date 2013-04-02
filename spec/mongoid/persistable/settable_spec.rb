require "spec_helper"

describe Mongoid::Persistable::Settable do

  describe "#set" do

    context "when the document is a root document" do

      let(:person) do
        Person.create
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      let!(:set) do
        person.set(title: "kaiser", test: "alias-test", dob: date)
      end

      it "sets the normal field to the new value" do
        expect(person.title).to eq("kaiser")
      end

      it "properly sets aliased fields" do
        expect(person.test).to eq("alias-test")
      end

      it "casts fields that need typecasting" do
        expect(person.dob).to eq(date)
      end

      it "returns true" do
        expect(set).to be_true
      end

      it "persists the normal field set" do
        expect(person.reload.title).to eq("kaiser")
      end

      it "resets the dirty attributes for the sets" do
        expect(person).to_not be_changed
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "kreuzbergstr")
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      let!(:set) do
        address.set(number: 44)
      end

      it "persists the normal field set" do
        expect(address.reload.number).to eq(44)
      end
    end
  end
end
