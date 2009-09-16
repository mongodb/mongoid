require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Associations::HasManyAssociation do

  before do
    @attributes = { :addresses => [ 
      { :street => "Street 1", :document_class => "Address" }, 
      { :street => "Street 2", :document_class => "Address" } ] }
    @document = stub(:attributes => @attributes)
  end

  describe "#[]" do

    before do
      @association = Mongoid::Associations::HasManyAssociation.new(:addresses, @document)
    end

    context "when the index is present in the association" do

      it "returns the document at the index" do
        @association[0].should be_a_kind_of(Address)
        @association[0].street.should == "Street 1"
      end

    end

    context "when the index is not present in the association" do

      it "returns nil" do
        @association[3].should be_nil
      end

    end

  end

  describe "#<<" do

    before do
      @association = Mongoid::Associations::HasManyAssociation.new(:addresses, @document)
    end

    it "appends the document to the end of the array" do
      @association << Address.new
      @association.length.should == 3
    end

  end

  describe "#first" do

    context "when there are elements in the array" do

      before do
        @association = Mongoid::Associations::HasManyAssociation.new(:addresses, @document)
      end

      it "returns the first element" do
        @association.first.should be_a_kind_of(Address)
        @association.first.street.should == "Street 1"
      end

    end

    context "when the array is empty" do

      before do
        @association = Mongoid::Associations::HasManyAssociation.new(:addresses, Person.new)
      end

      it "returns nil" do
        @association.first.should be_nil
      end

    end

  end

  describe "#length" do

    context "#length" do

      it "returns the length of the delegated array" do
        @association = Mongoid::Associations::HasManyAssociation.new(:addresses, @document)
        @association.length.should == 2
      end

    end

  end

  describe "#push" do

    before do
      @association = Mongoid::Associations::HasManyAssociation.new(:addresses, @document)
    end

    it "appends the document to the end of the array" do
      @association.push(Address.new)
      @association.length.should == 3
    end

  end

end
