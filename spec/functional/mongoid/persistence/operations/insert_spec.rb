require "spec_helper"

describe Mongoid::Persistence::Operations::Insert do

  before do
    Person.delete_all
  end

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  describe "#persist" do

    context "when the insert succeeded" do

      let(:person) do
        Person.create(:ssn => "323-21-1111")
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Person, person.id)
      end

      it "puts the document in the identity map" do
        in_map.should eq(person)
      end
    end
  end
end
