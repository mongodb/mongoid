require "spec_helper"

describe Mongoid::Factory do

  describe ".build" do

    before do
      @attributes = { "_type" => "Person", "title" => "Sir" }
    end

    it "instantiates based on the type" do
      person = Mongoid::Factory.build(@attributes)
      person.title.should == "Sir"
    end
  end
end
