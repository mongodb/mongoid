require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  has_many :addresses
  has_many :phone_numbers, :class_name => "Phone"
  has_one :name
  has_one :pet, :class_name => "Animal"
end

class Animal < Mongoid::Document
  field :name
  key :name
  belongs_to :person
end

class CountryCode < Mongoid::Document
  field :code, :type => Integer
  key :code
  belongs_to :phone_number
end

class Address < Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  key :street
  belongs_to :person
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

class Phone < Mongoid::Document
  field :number
  key :number
  belongs_to :person
  has_one :country_code
end

describe Mongoid::Associations do

  before do
    @collection = stub(:name => "people")
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
    @database = nil
    @collection = nil
  end

  describe "#association=" do

    context "when child is a has one" do

      before do
        @person = Person.new(:title => "Sir", :age => 30)
        @name = Name.new(:first_name => "Test", :last_name => "User")
        @person.name = @name
      end

      it "parentizes the association" do
        @name.parent.should == @person
      end

      it "sets the child attributes on the parent" do
        @person.attributes[:name].should ==
          HashWithIndifferentAccess.new({ :_id => "test-user", :first_name => "Test", :last_name => "User" })
      end

    end

  end

  describe "#belongs_to" do

    it "creates a reader for the association" do
      address = Address.new
      address.should respond_to(:person)
    end

    it "creates a writer for the association" do
      address = Address.new
      address.should respond_to(:person=)
    end

    it "allows the parent to be any type of class" do
      phone_number = Phone.new(:number => "415-555-1212")
      code = CountryCode.new(:code => 1)
      phone_number.country_code = code
      code.phone_number.should == phone_number
    end

  end

  describe "#has_many" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.addresses.should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:addresses)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:addresses=)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :addresses => [
            { :street => "Street 1" },
            { :street => "Street 2" } ] }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        address = Address.new(:street => "New Street")
        @person.addresses = [address]
        @person.addresses.first.street.should == "New Street"
      end

    end

    context "when a class_name is supplied" do

      before do
        @attributes = { :title => "Sir",
          :phone_numbers => [ { :number => "404-555-1212" } ]
        }
        @person = Person.new(@attributes)
      end

      it "sets the association name" do
        @person.phone_numbers.first.should == Phone.new(:number => "404-555-1212")
      end

    end

  end

  describe "#has_one" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.name.should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:name)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:name=)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :name => { :first_name => "Test" } }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        name = Name.new(:first_name => "New Name")
        @person.name = name
        @person.name.first_name.should == "New Name"
      end

    end

    context "when a class_name is supplied" do

      before do
        @attributes = { :title => "Sir",
          :pet => { :name => "Fido" }
        }
        @person = Person.new(@attributes)
      end

      it "sets the association name" do
        @person.pet.should == Animal.new(:name => "Fido")
      end

    end

  end

end
