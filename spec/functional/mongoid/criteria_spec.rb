require "spec_helper"

describe Mongoid::Criteria do

  before do
    Person.delete_all
  end

  context "when caching" do

    before do
      5.times do |n|
        Person.create!(
          :title => "Sir",
          :age => (n * 10),
          :aliases => ["D", "Durran"],
          :ssn => "#{n}"
        )
      end
    end

    let(:criteria) do
      Person.where(:title => "Sir").cache
    end

    it "iterates over the cursor only once" do
      criteria.size.should == 5
      Person.create!(:title => "Sir")
      criteria.size.should == 5
    end
  end

  describe "#id" do

    context "when using object ids" do

      before(:all) do
        Person.identity :type => BSON::ObjectId
      end

      let!(:person) do
        Person.create(
          :title => "Sir",
          :age => 33,
          :aliases => ["D", "Durran"],
          :things => [{:phone => 'HTC Incredible'}]
        )
      end

      it 'should find object with String args' do
        Person.criteria.id(person.id.to_s).first.should == person
      end

      it 'should find object with BSON::ObjectId  args' do
        Person.criteria.id(person.id).first.should == person
      end
    end

    context "when not using object ids" do

      before(:all) do
        Person.identity :type => String
      end

      after(:all) do
        Person.identity :type => BSON::ObjectId
      end

      let!(:person) do
        Person.create(
          :title => "Sir",
          :age => 33,
          :aliases => ["D", "Durran"],
          :things => [{:phone => 'HTC Incredible'}]
        )
      end

      it 'should find object with String args' do
        Person.criteria.id(person.id.to_s).first.should == person
      end

      it 'should not find object with BSON::ObjectId  args' do
        Person.criteria.id(BSON::ObjectId(person.id)).first.should == nil
      end
    end
  end

  describe "#to_json" do

    let(:criteria) do
      Person.all
    end

    before do
      Person.create(:ssn => "555-55-1212")
    end

    it "returns the results as a json string" do
      criteria.to_json.should include("\"ssn\":\"555-55-1212\"")
    end
  end

  describe "#parse!" do

    context "with nil args" do

      it "raises an error" do
        expect {
          Mongoid::Criteria.parse!(Person, :all, nil)
        }.to raise_error(Mongoid::Errors::InvalidOptions)
      end

    end

  end
end
