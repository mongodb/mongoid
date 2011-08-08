require "spec_helper"

describe Mongoid::Attributes do

  before do
    [ Person, Agent ].each(&:delete_all)
  end

  context "when persisting nil attributes" do

    let!(:person) do
      Person.create(:score => nil, :ssn => "555-66-7777")
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
      Person.create(:ssn => "123-77-7763")
    end

    it "does not override the default" do
      person.last_drink_taken_at.should == 1.day.ago.in_time_zone("Alaska").to_date
    end
  end

  context "when dynamic fields are not allowed" do

    before do
      Mongoid.configure.allow_dynamic_fields = false
    end

    after do
      Mongoid.configure.allow_dynamic_fields = true
    end

    context "and an embedded document has been persisted with a field that is no longer recognized" do

      before do
        Person.collection.insert 'pet' => { 'unrecognized_field' => true }
      end

      it "allows access to the legacy data" do
        Person.first.pet.read_attribute(:unrecognized_field).should == true
      end
    end
  end
end
