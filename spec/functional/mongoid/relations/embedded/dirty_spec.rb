require 'spec_helper'

describe "when initialize a model with an embedded model" do
  let(:person){Person.new :pet => Pet.new}

  it "should have changes in the embedded model" do
    person.pet.changes.should_not be_empty
  end

  it "should not have previous_changes in the embedded model" do
    person.pet.previous_changes.should be_nil
  end
end

describe "when creating a model with an embedded model" do
  let (:person){Person.create :pet => Pet.new}

  it "should not have changes in the embedded model" do
    person.pet.changes.should be_empty
  end

  it "should have previous_changes in the embedded model" do
    person.pet.previous_changes.should_not be_empty
  end
end

describe "when embedding a model on an already saved model" do
  let (:person) { Person.create }
  before do
    person.pet = Pet.new
  end

  it "should have not changes on the embedded model" do
    person.pet.changes.should be_empty
  end

  it "should have previous changes on the embedded model" do
    person.pet.previous_changes.should_not be_empty
  end

  describe "and saving the model" do
    before do
      person.save!
    end

    it "should not have changes on the embedded model" do
      person.pet.changes.should be_empty
    end

    it "should not have previous changes on the embedded model" do
      person.pet.previous_changes.should be_empty
    end
  end
end

