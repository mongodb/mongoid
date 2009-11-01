require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  field :age, :type => Integer, :default => 100
end

describe Mongoid::Extensions::Array::Conversions do

  describe "#mongoidize" do

    it "collects each of its attributes" do
      array = [
        Person.new(:_id => 1, :title => "Sir"),
        Person.new(:_id => 2, :title => "Madam")
      ]
      array.mongoidize.should ==
        [ HashWithIndifferentAccess.new({ :_id => 1, :title => "Sir", :age => 100 }),
          HashWithIndifferentAccess.new({ :_id => 2, :title => "Madam", :age => 100 }) ]
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
