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
        set.should eq(5)
      end

      it "persists the change" do
        reloaded.addresses.first.number.should eq(5)
      end
    end

    context "when setting a field with a value" do

      let!(:set) do
        person.set(:age, 2)
      end

      it "sets the provided value" do
        person.age.should eq(2)
      end

      it "returns the new value" do
        set.should eq(2)
      end

      it "persists the changes" do
        reloaded.age.should eq(2)
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
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
        person.lunch_time.should eq(date_time)
      end

      it "returns the new value" do
        set.should eq(date_time)
      end

      it "persists the changes" do
        reloaded.lunch_time.should eq(date_time)
      end

      it "resets the dirty attributes" do
        person.changes["lunch_time"].should be_nil
      end
    end

    context "when setting a field to false" do

      let!(:set) do
        person.set(:pets, false)
      end

      it "sets the provided value" do
        person.pets.should be_false
      end

      it "returns the new value" do
        set.should be_false
      end

      it "persists the changes" do
        reloaded.pets.should be_false
      end

      it "resets the dirty attributes" do
        person.changes["pets"].should be_nil
      end

    end

    context "when setting a nil field" do

      let!(:set) do
        person.set(:score, 2)
      end

      it "sets the value to the provided number" do
        person.score.should eq(2)
      end

      it "returns the new value" do
        set.should eq(2)
      end

      it "persists the changes" do
        reloaded.score.should eq(2)
      end

      it "resets the dirty attributes" do
        person.changes["score"].should be_nil
      end
    end

    context "when setting a non existant field" do

      let!(:set) do
        person.set(:high_score, 5)
      end

      it "sets the value to the provided number" do
        person.high_score.should eq(5)
      end

      it "returns the new value" do
        set.should eq(5)
      end

      it "persists the changes" do
        reloaded.high_score.should eq(5)
      end

      it "resets the dirty attributes" do
        person.changes["high_score"].should be_nil
      end
    end
  end
end
