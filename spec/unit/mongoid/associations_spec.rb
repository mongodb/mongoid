require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

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
        @person.attributes[:name].should == { :first_name => "Test", :last_name => "User" }
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

  end

end
