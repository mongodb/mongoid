# frozen_string_literal: true

require 'spec_helper'

describe "when initialize a model with an embedded model" do

  let(:person) do
    Person.new(pet: Pet.new)
  end

  it "has changes in the embedded model" do
    expect(person.pet.changes).to_not be_empty
  end

  it "does not have previous_changes in the embedded model" do
    expect(person.pet.previous_changes).to be_empty
  end
end

describe "when creating a model with an embedded model" do

  let(:person) do
    Person.create!(pet: Pet.new)
  end

  it "does not have changes in the embedded model" do
    expect(person.pet.changes).to be_empty
  end

  it "has previous_changes in the embedded model" do
    expect(person.pet.previous_changes).to_not be_empty
  end
end

describe "when embedding a model on an already saved model" do

  let(:person) do
    Person.create!
  end

  before do
    person.pet = Pet.new
  end

  it "has not changes on the embedded model" do
    expect(person.pet.changes).to be_empty
  end

  it "has previous changes on the embedded model" do
    expect(person.pet.previous_changes).to_not be_empty
  end

  describe "and saving the model" do

    before do
      person.save!
    end

    it "does not have changes on the embedded model" do
      expect(person.pet.changes).to be_empty
    end

    it "does not have previous changes on the embedded model" do
      expect(person.pet.previous_changes).to be_empty
    end
  end
end
