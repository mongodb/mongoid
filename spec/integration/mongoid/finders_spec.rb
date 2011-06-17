require "spec_helper"

describe Mongoid::Finders do

  describe "#find" do

    context "using string ids" do

      before do
        @documents = []
        @document = Person.create(:title => "Mrs.", :ssn => "another")
        3.times do |n|
          @documents << Person.create(:title => "Mr.", :ssn => "#{n}22")
        end
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

      context "with an array of ids as args" do

        context "when the documents are found" do

          it "returns an array of the documents" do
            @people = Person.find(@documents.map(&:id))
            @people.should == @documents
          end

        end

        context "when no documents found" do

          it "raises an error" do
            lambda { Person.find(["11", "21", "31"]) }.should raise_error
          end

        end
      end
    end

    context "using object ids" do

      before do
        Mongoid.use_object_ids = true
        @documents = []
        @document = Person.create(:title => "Mrs.", :ssn => "another")
        3.times do |n|
          @documents << Person.create(:title => "Mr.", :ssn => "#{n}22")
        end
      end

      after do
        Mongoid.use_object_ids = false
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

      context "with an array of ids as args" do

        context "when the documents are found" do

          it "returns an array of the documents even if the array of one id is given" do
            @people = Person.find([@documents.map(&:id).first])
            @people.should == [@documents.first]
          end

          it "returns an array of the documents" do
            @people = Person.find(@documents.map(&:id))
            @people.should == @documents
          end

        end

        context "when no documents found" do

          it "raises an error" do
            lambda { Person.find(["11", "21", "31"]) }.should raise_error
          end

        end
      end
    end
  end
end
