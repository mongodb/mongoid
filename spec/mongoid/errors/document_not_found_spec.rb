require "spec_helper"

describe Mongoid::Errors::DocumentNotFound do

  describe "#message" do

    context "when providing an id" do

      let(:error) do
        described_class.new(Person, "3")
      end

      it "contains document not found with the id" do
        error.message.should eq(
          "Document not found for class Person with id(s) 3."
        )
      end
    end

    context "when providing ids" do

      let(:error) do
        described_class.new(Person, [ 1, 2, 3 ])
      end

      it "contains document not found with the ids" do
        error.message.should eq(
          "Document not found for class Person with id(s) [1, 2, 3]."
        )
      end
    end

    context "when providing attributes" do

      let(:error) do
        described_class.new(Person, { :foo => "bar" })
      end

      it "contains document not found with the attributes" do
        error.message.should eq(
          "Document not found for class Person with attributes {:foo=>\"bar\"}."
        )
      end
    end
  end
end
