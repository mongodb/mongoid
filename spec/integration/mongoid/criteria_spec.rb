require "spec_helper"

describe Mongoid::Criteria do

  describe "#excludes" do

    before do
      @person = Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666")
    end

    after do
      Person.delete_all
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

  describe "#or" do

    let(:first) { Person.where(:ssn => "1") }
    let(:second) { Person.where(:ssn => "3") }
    let(:third) { Person.where(:ssn => "5") }
    let(:fourth) { Person.where(:ssn => "7") }

    before do
      10.times do |n|
        Person.create(:title => "Sir", :age => (n * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
      end
    end

    after do
      Person.delete_all
    end

    it "unions all the criteria together" do
      documents = first.or(second).or(third).or(fourth)
      documents.size.should == 4
      documents[0].ssn.should == "1"
      documents[1].ssn.should == "3"
      documents[2].ssn.should == "5"
      documents[3].ssn.should == "7"
    end

  end

  describe "#max" do

    before do
      10.times do |n|
        Person.create(:title => "Sir", :age => (n * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
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
        Person.create(:title => "Sir", :age => ((n + 1) * 10), :aliases => ["D", "Durran"], :ssn => "#{n}")
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
        Person.create(:title => "Sir", :age => 5, :aliases => ["D", "Durran"], :ssn => "#{n}")
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
