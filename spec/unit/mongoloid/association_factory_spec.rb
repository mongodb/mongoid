require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoloid::AssociationFactory do

  describe "#create" do

    before do
      @document = mock
      @attributes = { :test => "Test" }
    end

    context "when a defined association does not match the attribute type" do

      it "raises a TypeMismatchError" do
        @document.expects(:associations).returns({:test => "Test"})
        lambda { Mongoloid::AssociationFactory.create(@document, @attributes) }.should raise_error
      end

    end

  end

end
