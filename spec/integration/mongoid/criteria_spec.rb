require "spec_helper"

describe Mongoid::Criteria do

  before do
    Person.delete_all
  end

  context "when caching" do

    before do
      10.times do |n|
        Person.create!(:title => "Sir", :age => (n * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
      end
    end

    it "iterates over the cursor only once" do
      criteria = Person.where(:title => "Sir").cache

      criteria.collect.to_a.size.should == 10
      Person.create!(:title => "Sir")
      criteria.collect.to_a.size.should == 10
    end
  end

  describe "#id" do

    context "when using object ids" do

      before :all do
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

      before :all do
        Person.identity :type => String
      end

      after :all do
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
end
