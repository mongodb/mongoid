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

    before do
      @person = Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666")
    end

    context "when passed id" do

      it "it properly excludes ids" do
        Person.criteria.excludes(:id => @person.id).entries.should be_empty
      end

    end

    context "when passed _id" do

      it "it properly excludes ids" do
        Person.criteria.excludes(:_id => @person.id).entries.should be_empty
      end

    end

  end

  describe "#execute" do

    context "when reiterating" do

      before do
        @person = Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666")
      end

      it "executes the query again" do
        criteria = Person.all
        criteria.size.should == 1
        criteria.should_not be_empty
      end
    end
  end

  describe "#in" do

    context "when searching nil values" do

      before do
        @person = Person.create(:title => nil)
      end

      it "returns the correct document" do
        from_db = Person.any_in(:title => [ true, false, nil ]).first
        from_db.should == @person
      end
    end

    context "when searching false values" do

      before do
        @person = Person.create(:terms => false)
      end

      it "returns the correct document" do
        from_db = Person.criteria.in(:terms => [ true, false, nil ]).first
        from_db.should == @person
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

    before do
      @person = Person.create(:title => "Sir", :age => 33, :aliases => ["D", "Durran"], :things => [{:phone => 'HTC Incredible'}])
    end

    context "with complex criterion" do

      context "#all" do

        it "returns those matching an all clause" do
          Person.criteria.where(:title.all => ["Sir"]).should == [@person]
        end

      end

      context "#exists" do

        it "returns those matching an exists clause" do
          Person.criteria.where(:title.exists => true).should == [@person]
        end

      end

      context "#gt" do

        it "returns those matching a gt clause" do
          Person.criteria.where(:age.gt => 30).should == [@person]
        end

      end

      context "#gte" do

        it "returns those matching a gte clause" do
          Person.criteria.where(:age.gte => 33).should == [@person]
        end

      end

      context "#in" do

        it "returns those matching an in clause" do
          Person.criteria.where(:title.in => ["Sir", "Madam"]).should == [@person]
        end

      end

      context "#lt" do

        it "returns those matching a lt clause" do
          Person.criteria.where(:age.lt => 34).should == [@person]
        end

      end

      context "#lte" do

        it "returns those matching a lte clause" do
          Person.criteria.where(:age.lte => 33).should == [@person]
        end

      end

      context "#ne" do

        it "returns those matching a ne clause" do
          Person.criteria.where(:age.ne => 50).should == [@person]
        end

      end

      context "#nin" do

        it "returns those matching a nin clause" do
          Person.criteria.where(:title.nin => ["Esquire", "Congressman"]).should == [@person]
        end

      end

      context "#size" do

        it "returns those matching a size clause" do
          Person.criteria.where(:aliases.size => 2).should == [@person]
        end

      end

      context "#match" do

        it "returns those matching a partial element in a list" do
          Person.criteria.where(:things.match => {:phone => 'HTC Incredible'}).should == [@person]
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
      # Do it again!
      criteria.collect.to_a.size.should == 10
    end
  end

end
