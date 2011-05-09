require "spec_helper"

describe Mongoid::Factory do

  describe ".build" do

    context "when the _type attribute is present" do

      before do
        @attributes = { "_type" => "Person", "title" => "Sir" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end

    context "when _type is not preset" do

      before do
        @attributes = { "title" => "Sir" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end

    context "when _type is an empty string" do

      before do
        @attributes = { "title" => "Sir", "_type" => "" }
      end

      it "instantiates based on the type" do
        person = Mongoid::Factory.build(Person, @attributes)
        person.title.should == "Sir"
      end
    end
  end

  describe ".from_db" do

    context "when a type is in the attributes" do

      context "when the type is a class" do

        let(:attributes) do
          { "_type" => "Person", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Address, attributes)
        end

        it "generates based on the type" do
          document.should be_a(Person)
        end

        it "sets the attributes" do
          document.title.should == "Sir"
        end
      end

      context "when the type is empty" do

        let(:attributes) do
          { "_type" => "", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Person, attributes)
        end

        it "generates based on the provided class" do
          document.should be_a(Person)
        end

        it "sets the attributes" do
          document.title.should == "Sir"
        end
      end
    end

    context "when a type is not in the attributes" do

      let(:attributes) do
        { "title" => "Sir" }
      end

      let(:document) do
        described_class.from_db(Person, attributes)
      end

      it "generates based on the provided class" do
        document.should be_a(Person)
      end

      it "sets the attributes" do
        document.title.should == "Sir"
      end
    end
  end
end
