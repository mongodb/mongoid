require "spec_helper"

describe Mongoid::Persistence::Atomic::Unset do

  before do
    Person.delete_all
  end

  describe "#persist" do

    context "when unsetting a field" do

      let(:person) do
        Person.create(:ssn => "123-44-0091", :age => 100)
      end

      let!(:removed) do
        person.unset(:age)
      end

      it "removes the field" do
        person.age.should be_nil
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end

      it "returns nil" do
        removed.should be_nil
      end
    end
  end
end
