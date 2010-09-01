require "spec_helper"

describe Mongoid::Criteria do

  before do
    Person.delete_all
  end

  after do
    Person.delete_all
  end

  describe "#avg" do

    context "without results" do
      it "should return nil" do
        Person.avg(:age).should == nil
      end
    end

    context "with results" do
      before do
        10.times do |n|
          Person.create(:title => "Sir", :age => ((n + 1) * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
        end
      end

      it "provides min for the field provided" do
        Person.avg(:age).should == 55
      end
    end
  end

  describe "#excludes" do

    let(:person) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }

    context "when passed id" do

      it "it properly excludes ids" do
        Person.excludes(:id => person.id).entries.should be_empty
      end

    end

    context "when passed _id" do

      it "it properly excludes ids" do
        Person.excludes(:_id => person.id).entries.should be_empty
      end
    end
  end

  describe "#execute" do

    context "when reiterating" do

      let!(:person) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }

      it "executes the query again" do
        criteria = Person.all
        criteria.size.should == 1
        criteria.should_not be_empty
      end
    end
  end

  describe "#in" do

    context "when searching nil values" do

      let!(:person) { Person.create(:title => nil) }

      it "returns the correct document" do
        from_db = Person.any_in(:title => [ true, false, nil ]).first
        from_db.should == person
      end
    end

    context "when searching false values" do

      let!(:person) { Person.create(:terms => false) }

      it "returns the correct document" do
        from_db = Person.criteria.in(:terms => [ true, false, nil ]).first
        from_db.should == person
      end
    end
  end

  describe "#max" do

    context "without results" do
      it "should return nil" do
        Person.max(:age).should == nil
      end
    end

    context "with results" do
      before do
        10.times do |n|
          Person.create(:title => "Sir", :age => (n * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
        end
      end

      it "provides max for the field provided" do
        Person.max(:age).should == 90.0
      end
    end
  end

  describe "#min" do

    context "without results" do
      it "should return nil" do
        Person.min(:age).should == nil
      end
    end

    context "with results" do
      before do
        10.times do |n|
          Person.create(:title => "Sir", :age => ((n + 1) * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
        end
      end

      it "provides min for the field provided" do
        Person.min(:age).should == 10.0
      end
    end
  end

  describe "#any_of" do

    before do
      Person.create(:title => "Sir", :age => 5, :ssn => "098-76-5432")
      Person.create(:title => "Sir", :age => 7, :ssn => "098-76-5433")
      Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434")
    end

    context "with a single match" do

      it "returns any matching documents" do
        Person.where(:title => "Madam").any_of(:age => 1).count.should == 1
      end
    end

    context "when chaining for multiple matches" do

      it "returns any matching documents" do
        Person.any_of({ :age => 7 }, { :age.lt => 3 }).count.should == 2
      end
    end
  end

  describe "#sum" do

    context "without results" do
      it "should return nil" do
        Person.sum(:age).should == nil
      end
    end

    context "with results" do
      before do
        10.times do |n|
          Person.create(:title => "Sir", :age => 5, :aliases => ["D", "Durran"], :ssn => "#{n}")
        end
      end

      it "provides sum for the field provided" do
        Person.where(:age.gt => 3).sum(:age).should == 50.0
      end
    end
  end

  describe "#where" do

    let(:dob) { 33.years.ago.to_date }
    let(:lunch_time) { 30.minutes.ago }
    let!(:person) do
      Person.create(:title => "Sir", :dob => dob, :lunch_time => lunch_time, :age => 33, :aliases => ["D", "Durran"], :things => [{:phone => 'HTC Incredible'}])
    end

    context "chaining multiple where" do
      it "with the same key" do
        Person.where(:title => "Maam").where(:title => "Sir").should == [person]
      end
    end

    context "with untyped criteria" do

      it "typecasts integers" do
        Person.where(:age => "33").should == [person]
      end

      it "typecasts datetimes" do
        Person.where(:lunch_time => lunch_time.to_s).should == [person]
      end

      it "typecasts dates" do
        Person.where({:dob => dob.to_s}).should == [person]
      end

      it "typecasts times with zones" do
        time = lunch_time.in_time_zone("Alaska")
        Person.where(:lunch_time => time).should == [person]
      end

      it "typecasts array elements" do
        Person.where(:age.in => [17, "33"]).should == [person]
      end

      it "typecasts size criterion to integer" do
        Person.where(:aliases.size => "2").should == [person]
      end

      it "typecasts exists criterion to boolean" do
        Person.where(:score.exists => "f").should == [person]
      end

    end

    context "with multiple complex criteria" do
      before do
        Person.create(:title => "Mrs", :age => 29)
        Person.create(:title => "Ms", :age => 41)
      end
      it "returns those matching both criteria" do
        Person.where(:age.gt => 30, :age.lt => 40).should == [person]
      end
    end

    context "with complex criterion" do

      context "#all" do

        it "returns those matching an all clause" do
          Person.where(:aliases.all => ["D", "Durran"]).should == [person]
        end

      end

      context "#exists" do

        it "returns those matching an exists clause" do
          Person.where(:title.exists => true).should == [person]
        end

      end

      context "#gt" do

        it "returns those matching a gt clause" do
          Person.where(:age.gt => 30).should == [person]
        end

      end

      context "#gte" do

        it "returns those matching a gte clause" do
          Person.where(:age.gte => 33).should == [person]
        end

      end

      context "#in" do

        it "returns those matching an in clause" do
          Person.where(:title.in => ["Sir", "Madam"]).should == [person]
        end

      end

      context "#lt" do

        it "returns those matching a lt clause" do
          Person.where(:age.lt => 34).should == [person]
        end

      end

      context "#lte" do

        it "returns those matching a lte clause" do
          Person.where(:age.lte => 33).should == [person]
        end

      end

      context "#ne" do

        it "returns those matching a ne clause" do
          Person.where(:age.ne => 50).should == [person]
        end

      end

      context "#nin" do

        it "returns those matching a nin clause" do
          Person.where(:title.nin => ["Esquire", "Congressman"]).should == [person]
        end

      end

      context "#size" do

        it "returns those matching a size clause" do
          Person.where(:aliases.size => 2).should == [person]
        end

      end

      context "#match" do

        it "returns those matching a partial element in a list" do
          Person.where(:things.matches => { :phone => "HTC Incredible" }).should == [person]
        end

      end

    end

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
        @previous_id_type = ::Person._id_type
        Person.identity :type => BSON::ObjectId
      end

      after :all do
        Person.identity :type => @previous_id_type
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
        @previous_id_type = Person._id_type
        Person.identity :type => String
      end

      after :all do
        Person.identity :type => @previous_id_type
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
