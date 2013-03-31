require "spec_helper"

describe Mongoid::Persistence::Atomic::Sets do

  describe "#set" do

    let(:person) do
      Person.create(age: 100, pets: true)
    end

    let(:reloaded) do
      person.reload
    end

    context "when setting a field on an embedded document" do

      let(:address) do
        person.addresses.create(street: "Tauentzienstr", number: 5)
      end

      let!(:set) do
        address.set(:number, 5)
      end

      it "sets the provided value" do
        expect(set).to eq(5)
      end

      it "persists the change" do
        expect(reloaded.addresses.first.number).to eq(5)
      end
    end

    context "when setting a field with a value" do

      let!(:set) do
        person.set(:age, 2)
      end

      it "sets the provided value" do
        expect(person.age).to eq(2)
      end

      it "returns the new value" do
        expect(set).to eq(2)
      end

      it "persists the changes" do
        expect(reloaded.age).to eq(2)
      end

      it "resets the dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end
    end

    context "when setting a field with a value that must be cast" do

      let(:date_time) do
        DateTime.new(2012, 1, 2)
      end

      let!(:set) do
        person.set(:lunch_time, date_time)
      end

      it "sets the provided value" do
        expect(person.lunch_time).to eq(date_time)
      end

      it "returns the new value" do
        expect(set).to eq(date_time)
      end

      it "persists the changes" do
        expect(reloaded.lunch_time).to eq(date_time)
      end

      it "resets the dirty attributes" do
        expect(person.changes["lunch_time"]).to be_nil
      end
    end

    context "when setting a field to false" do

      let!(:set) do
        person.set(:pets, false)
      end

      it "sets the provided value" do
        expect(person.pets).to be_false
      end

      it "returns the new value" do
        expect(set).to be_false
      end

      it "persists the changes" do
        expect(reloaded.pets).to be_false
      end

      it "resets the dirty attributes" do
        expect(person.changes["pets"]).to be_nil
      end

    end

    context "when setting a nil field" do

      let!(:set) do
        person.set(:score, 2)
      end

      it "sets the value to the provided number" do
        expect(person.score).to eq(2)
      end

      it "returns the new value" do
        expect(set).to eq(2)
      end

      it "persists the changes" do
        expect(reloaded.score).to eq(2)
      end

      it "resets the dirty attributes" do
        expect(person.changes["score"]).to be_nil
      end
    end

    context "when setting a non existant field" do

      let!(:set) do
        person.set(:high_score, 5)
      end

      it "sets the value to the provided number" do
        expect(person.high_score).to eq(5)
      end

      it "returns the new value" do
        expect(set).to eq(5)
      end

      it "persists the changes" do
        expect(reloaded.high_score).to eq(5)
      end

      it "resets the dirty attributes" do
        expect(person.changes["high_score"]).to be_nil
      end
    end
  end
end
