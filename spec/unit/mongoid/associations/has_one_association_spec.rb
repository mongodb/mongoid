require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Associations::HasOneAssociation do

  before do
    @attributes = { :name => { :first_name => "Drexel" } }
    @document = stub(:attributes => @attributes)
  end

  describe "#decorate!" do

    before do
      @association = Mongoid::Associations::HasOneAssociation.new(:name, @document)
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