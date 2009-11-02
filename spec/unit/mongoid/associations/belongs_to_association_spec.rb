require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

describe Mongoid::Associations::BelongsToAssociation do

  before do
    @parent = Name.new(:first_name => "Drexel")
    @document = stub(:parent => @parent)
  end

  describe "#find" do

    before do
      @association = Mongoid::Associations::BelongsToAssociation.new(@document)
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
      @association = Mongoid::Associations::BelongsToAssociation.new(@document)
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
