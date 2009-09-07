require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoloid::Associations::BelongsToAssociation do

  before do
    @document = Name.new(:first_name => "Drexel")
  end

  describe "#method_missing" do

    before do
      @association = Mongoloid::Associations::BelongsToAssociation.new(@document)
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