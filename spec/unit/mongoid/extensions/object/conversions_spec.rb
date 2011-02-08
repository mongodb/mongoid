require "spec_helper"

describe Mongoid::Extensions::Object::Conversions do

  describe "#get" do

    let(:attributes) do
      { :_id => BSON::ObjectId.new.to_s, :title => "Sir", :age => 100 }
    end

    context "when the value is a mongoid document" do

      it "instantiates a new class from the attributes" do
        Person.get(attributes).should == Person.new(attributes)
      end
    end

    context "when the value is a primitive type" do

      it "it returns the value" do
        Object.get(12).should == 12
        Object.get(13.04).should == 13.04
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Person.get(nil).should be_nil
      end
    end
  end

  describe "#set" do

    context "when object has attributes" do

      let(:attributes) do
        {
          "_id" => "test",
          "title" => "Sir",
          "age" => 100,
          "_type" => "Person",
          "blood_alcohol_content" => 0.0,
          "pets" => false
        }
      end

      let(:quiz) do
        Quiz.instantiate(attributes)
      end

      it "converts the object to a hash" do
        Quiz.set(quiz).except("_id").should == attributes.except("_id")
      end
    end
  end
end
