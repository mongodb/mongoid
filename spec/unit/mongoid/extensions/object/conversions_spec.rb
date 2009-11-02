require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb"))

describe Mongoid::Extensions::Object::Conversions do

  describe "#mongoidize" do

    it "returns its attributes" do
      Person.new(:_id => 1, :title => "Sir").mongoidize.should ==
        { "_id" => 1, "title" => "Sir", "age" => 100 }
    end

  end

  describe "#get" do

    before do
      @attributes = { :_id => "test", :title => "Sir", :age => 100 }
    end

    it "instantiates a new class from the attributes" do
      Person.get(@attributes).should == Person.new(@attributes)
    end

  end

  describe "#set" do

    context "when object has attributes" do

      before do
        @attributes = { "_id" => "test", "title" => "Sir", "age" => 100 }
        @person = Person.new(@attributes)
      end

      it "converts the object to a hash" do
        Person.set(@person).should == @attributes
      end

    end

  end

end
