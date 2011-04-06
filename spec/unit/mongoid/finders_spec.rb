require "spec_helper"

describe Mongoid::Finders do

  let(:collection) do
    stub(:name => "people")
  end

  let(:database) do
    stub(:collection => collection)
  end

  before do
    Mongoid.stubs(:database).returns(database)
  end

  describe ".all" do

    let(:conditions) do
      { :conditions => { :test => "Test" } }
    end

    let(:criteria) do
      stub
    end

    context "when a selector is provided" do

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, conditions)
      end

      it "finds from the collection and instantiate objects for each returned" do
        Person.all(conditions)
      end
    end

    context "when a selector is not provided" do

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, nil)
      end

      it "finds from the collection and instantiate objects for each returned" do
        Person.all
      end
    end
  end

  describe ".all_in" do

    let(:criteria) do
      Person.all_in(:aliases => [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :aliases => { "$all" => [ "Bond", "007" ] } }
    end
  end

  describe ".any_in" do

    let(:criteria) do
      Person.any_in(:aliases => [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :aliases => { "$in" => [ "Bond", "007" ] } }
    end
  end

  describe ".count" do

    let(:conditions) do
      { :conditions => { :title => "Sir" } }
    end

    let(:criteria) do
      stub
    end

    context "with options provided" do

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, conditions).returns(criteria)
        criteria.expects(:count).returns(10)
      end

      it "delegates to the criteria api" do
        Person.count(conditions).should == 10
      end
    end

    context "when no options provided" do

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, nil).returns(criteria)
        criteria.expects(:count).returns(10)
      end

      it "adds in the default parameters" do
        Person.count.should == 10
      end
    end
  end

  describe ".exists?" do

    let(:criteria) do
      stub
    end

    context "when options are provided" do

      let(:conditions) do
        { :conditions => { :title => "Sir" } }
      end

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, conditions).returns(criteria)
        criteria.expects(:limit).with(1).returns(criteria)
      end

      context "when count is greater than zero" do

        before do
          criteria.expects(:count).returns(1)
        end

        it "returns true" do
          Person.exists?(conditions).should be_true
        end
      end

      context "when the count is zero" do

        before do
          criteria.expects(:count).returns(0)
        end

        it "returns false" do
          Person.exists?(conditions).should be_false
        end
      end
    end

    context "when no options are provided" do

      before do
        Mongoid::Criteria.expects(:new).with(Person, false).returns(criteria)
        criteria.expects(:find).with(:all, nil).returns(criteria)
        criteria.expects(:limit).with(1).returns(criteria)
      end

      context "when count is greater than zero" do

        before do
          criteria.expects(:count).returns(1)
        end

        it "returns true" do
          Person.exists?.should be_true
        end
      end

      context "when the count is zero" do

        before do
          criteria.expects(:count).returns(0)
        end

        it "returns false" do
          Person.exists?.should be_false
        end
      end
    end
  end

  describe ".excludes" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.excludes(:title => "Sir")
      criteria.selector.should == { :title => { "$ne" => "Sir" } }
    end
  end

  describe ".only" do

    let(:criteria) do
      Person.only(:title, :age)
    end

    it "returns a new criteria with select conditions added" do
      criteria.options.should == { :fields => {:_type => 1, :title => 1, :age => 1} }
    end
  end

  describe ".sum" do

    let(:criteria) do
      stub
    end

    before do
      Person.expects(:criteria).returns(criteria)
      criteria.expects(:sum).with(:age).returns(50.0)
    end

    it "returns the sum of a new criteria" do
      Person.sum(:age).should == 50.0
    end
  end

  describe ".where" do

    let(:criteria) do
      Person.where(:title => "Sir")
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :title => "Sir" }
    end
  end

  describe ".near" do

    let(:criteria) do
      Address.near(:latlng => [37.761523, -122.423575, 1])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should ==
        { :latlng => { "$near" => [37.761523, -122.423575, 1] } }
    end
  end
end
