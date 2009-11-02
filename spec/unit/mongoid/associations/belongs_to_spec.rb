require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  has_one :name
  has_many :addresses
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

class Address < Mongoid::Document
  field :street
  belongs_to :person
end

describe Mongoid::Associations::BelongsTo do

  describe "#update" do

    context "when child is a has one" do

      before do
        @name = Name.new(:first_name => "Test", :last_name => "User")
        @person = Person.new(:title => "Mrs")
        Mongoid::Associations::BelongsTo.update(@name, @person)
      end

      it "updates the parent document" do
        @person.name.should == @name
        @person.attributes[:name].except(:_id).should ==
          { "first_name" => "Test", "last_name" => "User" }
      end

    end

    context "when child is a has many" do

      before do
        @address = Address.new(:street => "Broadway")
        @person = Person.new(:title => "Mrs")
        Mongoid::Associations::BelongsTo.update(@address, @person)
      end

      it "updates the parent document" do
        @person.addresses.first.should == @address
      end

    end

  end

  describe "#find" do

    before do
      @parent = Name.new(:first_name => "Drexel")
      @document = stub(:parent => @parent)
      @association = Mongoid::Associations::BelongsTo.new(@document)
    end

    context "when finding by id" do

      it "returns the document in the array with that id" do
        name = @association.find(Mongo::ObjectID.new.to_s)
        name.should == @parent
      end

    end

  end

  context "when decorating" do

    before do
      @parent = Name.new(:first_name => "Drexel")
      @document = stub(:parent => @parent)
      @association = Mongoid::Associations::BelongsTo.new(@document)
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.first_name.should == "Drexel"
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.first_name = "Test"
        @association.first_name.should == "Test"
      end

    end

  end

end
