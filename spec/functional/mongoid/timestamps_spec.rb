require "spec_helper"

describe Mongoid::Timestamps do

  before do
    Person.delete_all
  end

  context "when only embedded documents have changed" do

    let!(:person) do
      Person.create(:ssn => "123-12-1212", :updated_at => 2.days.ago)
    end

    let!(:address) do
      person.addresses.create(:street => "Karl Marx Strasse")
    end

    let!(:updated_at) do
      person.updated_at
    end

    before do
      address.number = 1
      person.save
    end

    it "updates the root document updated at" do
      person.updated_at.should be_within(5).of(Time.now)
    end
  end
end
