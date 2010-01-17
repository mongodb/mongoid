require "spec_helper"

describe Mongoid::Validations::Uniqueness do

  describe "#validate_each" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::Uniqueness.new(:attributes => @document.attributes) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:empty? => false)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

    end

    context "when no document exists with the attribute" do

      before do
        @criteria = stub(:empty? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds no errors" do
        @document.errors[:title].should be_empty
      end

    end

  end

end
