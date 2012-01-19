require 'spec_helper'

describe "when initialize a model with an embedded model" do

  before do
    Person.delete_all
  end

  let(:person) do
    Person.new(:ssn => "444-44-1234", :pet => Pet.new)
  end

  it "has changes in the embedded model" do
    person.pet.changes.should_not be_empty
  end

  it "does not have previous_changes in the embedded model" do
    person.pet.previous_changes.should be_nil
  end
end

describe "when creating a model with an embedded model" do

  let(:person) do
    Person.create(:ssn => "123-22-2222", :pet => Pet.new)
  end

  it "does not have changes in the embedded model" do
    person.pet.changes.should be_empty
  end

  it "has previous_changes in the embedded model" do
    person.pet.previous_changes.should_not be_empty
  end
end

describe "when embedding a model on an already saved model" do

  let(:person) do
    Person.create(:ssn => "654-33-2222")
  end

  before do
    person.pet = Pet.new
  end

  it "has not changes on the embedded model" do
    person.pet.changes.should be_empty
  end

  it "has previous changes on the embedded model" do
    person.pet.previous_changes.should_not be_empty
  end

  describe "and saving the model" do

    before do
      person.save!
    end

    it "does not have changes on the embedded model" do
      person.pet.changes.should be_empty
    end

    it "does not have previous changes on the embedded model" do
      person.pet.previous_changes.should be_empty
    end
  end
end
