require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Associations::HasOne do

  before do
    @attributes = { :mixed_drink => { :name => "Jack and Coke" } }
    @document = stub(:attributes => @attributes, :update => true)
  end

  describe "#build" do

    before do
      @association = Mongoid::Associations::HasOne.new(:name, @document)
    end

    it "creates a new document with the asssociations set up" do
      child = @association.build(:first_name => "Test", :last_name => "User")
      child.first_name.should == "Test"
      child.last_name.should == "User"
      child.parent.should_not be_nil
    end

    context "when the association already exists" do

      before do
        @person = Person.new(:title => "Sir")
        @name = Name.new(:first_name => "Prince", :last_name => "Humperdink")
        @person.name = @name
      end

      it "replaces the existing association" do
        @person.name.build(:first_name => "Princess", :last_name => "Buttercup")
        @person.name.first_name.should == "Princess"
        @person.name.person.should == @person
      end

    end

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
