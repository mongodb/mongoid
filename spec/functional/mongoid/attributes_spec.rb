require "spec_helper"

describe Mongoid::Attributes do

  context "when persisting nil attributes" do

    let!(:person) do
      Person.create(:score => nil, :ssn => "555-66-7777")
    end

    after do
      Person.delete_all
      Agent.delete_all
    end

    it "has an entry in the attributes" do
      person.reload.attributes.should have_key("score")
    end
  end

  context "with a default last_drink_taken_at" do

    let(:person) { Person.new }

    it "saves the default" do
      expect { person.save }.to_not raise_error
      person.last_drink_taken_at.should == 1.day.ago.in_time_zone("Alaska").to_date
    end
  end

  context "when default values are defined" do

    let(:person) do
      Person.create
    end

    it "does not override the default" do
      person.last_drink_taken_at.should == 1.day.ago.in_time_zone("Alaska").to_date
    end
  end
end
