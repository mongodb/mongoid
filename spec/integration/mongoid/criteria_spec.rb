require "spec_helper"

describe Mongoid::Criteria do

  describe "#max" do

    before do
      10.times do |n|
        Person.create(:title => "Sir", :age => (n * 10), :aliases => ["D", "Durran"])
      end
    end

    after do
      Person.delete_all
    end

    it "provides max for the field provided" do
      Person.max(:age).should == 90.0
    end

  end

  describe "#min" do

    before do
      10.times do |n|
        Person.create(:title => "Sir", :age => ((n + 1) * 10), :aliases => ["D", "Durran"])
      end
    end

    after do
      Person.delete_all
    end

    it "provides min for the field provided" do
      Person.min(:age).should == 10.0
    end

  end

  describe "#sum" do

    before do
      10.times do |n|
        Person.create(:title => "Sir", :age => 5, :aliases => ["D", "Durran"])
      end
    end

    after do
      Person.delete_all
    end

    it "provides sum for the field provided" do
      Person.where(:age.gt => 3).sum(:age).should == 50.0
    end

  end

  describe "#where" do

    before do
      @person = Person.create(:title => "Sir", :age => 33, :aliases => ["D", "Durran"])
    end

    after do
      Person.delete_all
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

    end

  end

end
