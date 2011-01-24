require "spec_helper"

describe Mongoid::Finders do

  before do
    Person.delete_all
  end

  describe "#find" do

    context "when using string ids" do

      let!(:person) do
        Person.create(:title => "Mrs.", :ssn => "another")
      end

      let!(:documents) do
        3.times.map do |n|
          Person.create(:title => "Mr.", :ssn => "#{n}22")
        end
      end

      before(:all) do
        Person.identity :type => String
      end

      after(:all) do
        Person.identity :type => BSON::ObjectId
      end

      context "with an id as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id).should == person
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new.to_s)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passed an array of ids" do

        context "when the documents are found" do

          let(:people) do
            Person.find(documents.map(&:id))
          end

          it "returns an array of the documents" do
            people.should == documents
          end
        end

        context "when no documents found" do

          it "raises an error" do
            expect {
              Person.find([
                BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s
              ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passing an empty array" do

        let(:people) do
          Person.find([])
        end

        it "returns an empty array" do
          people.should be_empty
        end
      end
    end

    context "when using object ids" do

      let!(:person) do
        Person.create(:title => "Mrs.", :ssn => "another")
      end

      let!(:documents) do
        3.times.map do |n|
          Person.create(:title => "Mr.", :ssn => "#{n}22")
        end
      end

      before(:all) do
        Person.identity :type => BSON::ObjectId
      end

      context "when passed a BSON::ObjectId as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id).should == person
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passed a string id as an argument" do

        context "when the document is found" do

          it "returns the document" do
            Person.find(person.id.to_s).should == person
          end
        end

        context "when the document is not found" do

          it "raises an error" do
            expect {
              Person.find(BSON::ObjectId.new.to_s)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when passed an array of ids as args" do

        context "when the documents are found" do

          let(:people) do
            Person.find(documents.map(&:id))
          end

          it "returns an array of the documents" do
            people.should == documents
          end
        end

        context "when no documents found" do

          it "raises an error" do
            expect {
              Person.find([
                BSON::ObjectId.new, BSON::ObjectId.new
              ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end
    end
  end
end
