require File.expand_path(File.join(File.dirname(__FILE__), "/../../spec_helper.rb"))

describe Mongoid::DynamicFinder do

  describe "#conditions" do

    before do
      @finder = Mongoid::DynamicFinder.new(:find_by_title_and_age, "Sir", 30)
      @conditions = { "title" => "Sir", "age" => 30 }
    end

    it "returns the conditions hash for the criteria" do
      @finder.conditions.should == @conditions
    end

    context "when id is an attribute" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_by_id, "5")
        @conditions = { "_id" => "5" }
      end

      it "converts to _id" do
        @finder.conditions.should == @conditions
      end

    end

  end

  describe "#create" do

    context "when initializing" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_or_initialize_by_title_and_age, "Sir", 30)
      end

      it "instantiates a new document" do
        person = @finder.create(Person)
        person.title.should == "Sir"
        person.age.should == 30
      end

    end

    context "when creating" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_or_create_by_title_and_age, "Sir", 30)
        @person = stub
      end

      it "creates a new document" do
        Person.expects(:create).with(@finder.conditions).returns(@person)
        person = @finder.create(Person)
        person.should == @person
      end

    end

  end

  describe ".initialize" do

    context "when find_by*" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_by_title_and_age, "Sir", 30)
      end

      it "sets a first finder and attributes" do
        @finder.finder.should == :first
        @finder.conditions.should == { "title" => "Sir", "age" => 30 }
      end

    end

    context "when find_all_by*" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_all_by_title_and_age, "Sir", 30)
      end

      it "sets an all finder and attributes" do
        @finder.finder.should == :all
        @finder.conditions.should == { "title" => "Sir", "age" => 30 }
      end

    end

    context "when find_last_by*" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_last_by_title_and_age, "Sir", 30)
      end

      it "sets a last finder and attributes" do
        @finder.finder.should == :last
        @finder.conditions.should == { "title" => "Sir", "age" => 30 }
      end

    end

    context "when find_or_initialize_by*" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_or_initialize_by_title_and_age, "Sir", 30)
      end

      it "sets a first finder with attributes or a new" do
        @finder.finder.should == :first
        @finder.conditions.should == { "title" => "Sir", "age" => 30 }
      end

    end

    context "when find_or_create_by*" do

      before do
        @finder = Mongoid::DynamicFinder.new(:find_or_create_by_title_and_age, "Sir", 30)
      end

      it "sets a first finder with attributes or a create" do
        @finder.finder.should == :first
        @finder.conditions.should == { "title" => "Sir", "age" => 30 }
      end

    end

    context "when invalid finder name" do

      before do
        @finder = Mongoid::DynamicFinder.new(:bleh)
      end

      it "sets a nil finder" do
        @finder.finder.should be_nil
      end

    end

  end

end
