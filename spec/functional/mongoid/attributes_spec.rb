require "spec_helper"

describe Mongoid::Attributes do

  before do
    [ Person, Agent, Account ].each(&:delete_all)
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

    context "when no value exists in the database" do

      let(:person) do
        Person.create(:ssn => "123-77-7763")
      end

      it "applies the default value" do
        person.last_drink_taken_at.should == 1.day.ago.in_time_zone("Alaska").to_date
      end
    end

    context "when a value exists in the database" do

      context "when the value is not nil" do

        let!(:person) do
          Person.create(:ssn => "789-67-7861", :age => 50)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "does not set the default" do
          from_db.age.should eq(50)
        end
      end

      context "when the value is explicitly nil" do

        let!(:person) do
          Person.create(:ssn => "789-67-7861", :age => nil)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "does not set the default" do
          from_db.age.should be_nil
        end
      end

      context "when the default is a proc" do

        let!(:account) do
          Account.create(:name => "savings", :balance => "100")
        end

        let(:from_db) do
          Account.find(account.id)
        end

        it "applies the defaults after all attributes are set" do
          from_db.should be_balanced
        end
      end
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
