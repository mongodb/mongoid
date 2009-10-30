require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Associations::HasOneAssociation do

  before do
    @attributes = { :mixed_drink => { :name => "Jack and Coke" } }
    @document = stub(:attributes => @attributes)
  end

  describe "#decorate!" do

    before do
      @association = Mongoid::Associations::HasOneAssociation.new(:mixed_drink, @document)
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
