require "spec_helper"

describe Mongoid::Extensions::Object::Conversions do

  describe "#get" do

    before do
      @attributes = { :_id => "test", :title => "Sir", :age => 100 }
    end

    it "instantiates a new class from the attributes" do
      Person.get(@attributes).should == Person.new(@attributes)
    end

    context "when the value is nil" do

      it "returns nil" do
        Person.get(nil).should be_nil
      end
    end
  end

  describe "#set" do

    context "when object has attributes" do

      before do
        @attributes = {
          "_id" => "test",
          "title" => "Sir",
          "age" => 100,
          "_type" => "Person",
          "blood_alcohol_content" => 0.0,
          "pets" => false
        }
        @person = Person.instantiate(@attributes)
      end

      it "converts the object to a hash" do
        Person.set(@person).except("_id").should == @attributes.except("_id")
      end
    end
  end
end
