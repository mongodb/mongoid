require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

class MixedDrink < Mongoid::Document
  field :name
end

class Person < Mongoid::Document
  field :title
  has_one :name
end

class Name < Mongoid::Document
  field :first_name
  key :first_name
  belongs_to :person
end

describe Mongoid::Associations::HasOne do

  before do
    @attributes = { :mixed_drink => { :name => "Jack and Coke" } }
    @document = stub(:attributes => @attributes, :update => true)
  end

  describe "#update" do

    before do
      @name = Name.new(:first_name => "Donald")
      @person = Person.new(:title => "Sir")
      Mongoid::Associations::HasOne.update(@name, @person, :name)
    end

    it "parentizes the child document" do
      @name.parent.should == @person
    end

    it "sets the attributes of the child on the parent" do
      @person.attributes[:name].should ==
        { "_id" => "donald", "first_name" => "Donald" }
    end

  end

  describe "#decorate!" do

    before do
      @association = Mongoid::Associations::HasOne.new(:mixed_drink, @document)
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.name.should == "Jack and Coke"
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.name = "Jack and Coke"
        @association.name.should == "Jack and Coke"
      end

    end

  end

end
