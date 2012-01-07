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
