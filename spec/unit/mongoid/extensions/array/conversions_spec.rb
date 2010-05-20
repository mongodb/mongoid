require "spec_helper"

describe Mongoid::Extensions::Array::Conversions do

  describe "#mongoidize" do

    it "collects each of its attributes" do
      array = [
        Person.new(:_id => 1, :title => "Sir"),
      ]
      array.mongoidize.should ==
        [ {
            "_id" => 1,
            "title" => "Sir",
            "age" => 100,
            "_type" => "Person",
            "blood_alcohol_content" => 0.0,
            "pets" => false,
            "preference_ids" => []
          }
        ]
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
