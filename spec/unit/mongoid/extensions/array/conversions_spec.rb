require "spec_helper"

describe Mongoid::Extensions::Array::Conversions do

  describe "#mongoidize" do

    it "collects each of its attributes" do
      array = [
        Person.new(:_id => 1, :title => "Sir"),
        Person.new(:_id => 2, :title => "Madam")
      ]
      array.mongoidize.should ==
        [ HashWithIndifferentAccess.new({ :_id => 1, :title => "Sir", :age => 100, :_type => "Person" }),
          HashWithIndifferentAccess.new({ :_id => 2, :title => "Madam", :age => 100, :_type => "Person" }) ]
    end

  end

  describe "#get" do

    it "returns the array" do
      Array.get(["test"]).should == ["test"]
    end

  end

  describe "#set" do

    it "returns the array" do
      Array.set(["test"]).should == ["test"]
    end

  end

end
