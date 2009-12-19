require "spec_helper"

describe Mongoid::Finders do

  describe "#find" do

    before do
      @document = Person.create(:title => "Mrs.")
    end

    after do
      Person.delete_all
    end

    context "with an id as an argument" do

      context "when the document is found" do

        it "returns the document" do
          Person.find(@document.id).should == @document
        end

      end

      context "when the document is not found" do

        it "raises an error" do
          lambda { Person.find("5") }.should raise_error
        end

      end

    end

  end

end
