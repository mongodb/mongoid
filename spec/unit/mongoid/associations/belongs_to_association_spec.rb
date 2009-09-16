require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Associations::BelongsToAssociation do

  before do
    @parent = Name.new(:first_name => "Drexel")
    @document = stub(:parent => @parent)
  end

  describe "#method_missing" do

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
