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

  context "when the block is omitted" do

    before do
      3.times do |n|
        Person.create!(:title => "Sir", :ssn => "#{n}")
      end
    end

    let(:cursor) do
      Person.where(:title => "Sir").asc(:ssn).each
    end

    it "emits the next document on .next" do
      cursor.next.ssn.should == "0"
      cursor.next.ssn.should == "1"
      cursor.next.ssn.should == "2"
      cursor.next.should     == nil
      cursor.next.should     == nil
    end

  end

  describe "#find" do

    context "when using object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
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
        Person.find(person.id.to_s).should == person
      end

      it 'should find object with BSON::ObjectId  args' do
        Person.find(person.id).should == person
      end
    end

    context "when not using object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new.to_s }
        )
      end

      after(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      let!(:person) do
        Person.create(
          :title => "Sir",
          :age => 33,
          :aliases => ["D", "Durran"],
          :things => [{:phone => 'HTC Incredible'}]
        )
      end

      it 'should find the object with a matching String arg' do
        Person.find(person.id.to_s).should == person
      end

      it 'should find the object with a matching BSON::ObjectId argument' do
        Person.find(BSON::ObjectId(person.id)).should eq(person)
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
end
