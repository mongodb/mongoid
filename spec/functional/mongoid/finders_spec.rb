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

        context "find by title" do
          it "returns the document is found" do
            Person.find_by_title("Mrs.").should == Person.where("title" => "Mrs.")
            Person.find_by_title("Mrs.").last.should == person
            Person.find_by_title_and_ssn("Mrs.", "another").last.should == person
            Person.find_last_by_title_and_ssn("Mrs.", "another").should == person
            Person.find_first_by_title_and_ssn("Mrs.", "another").should == person
          end
        end

        context "find method not exist" do
          it "raise an error" do
            expect {
              Person.no_method
            }.to raise_error(NoMethodError)            
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

  describe ".find_or_create_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(:title => "Senior", :ssn => "333-22-1111")
      end

      it "returns the document" do
        Person.find_or_create_by(:title => "Senior").should == person
      end
    end

    context "when the document is not found" do

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_create_by(:title => "Senorita", :ssn => "1234567")
        end

        it "creates a persisted document" do
          person.should be_persisted
        end

        it "sets the attributes" do
          person.title.should == "Senorita"
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_create_by(:title => "Senorita", :ssn => "1") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          person.should be_persisted
        end

        it "sets the attributes" do
          person.title.should == "Senorita"
        end

        it "calls the block" do
          person.pets.should == true
        end
      end
    end
  end

  describe ".find_or_initialize_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(:title => "Senior", :ssn => "333-22-1111")
      end

      it "returns the document" do
        Person.find_or_initialize_by(:title => "Senior").should == person
      end
    end

    context "when the document is not found" do

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(:title => "Senorita", :ssn => "1234567")
        end

        it "creates a new document" do
          person.should be_new
        end

        it "sets the attributes" do
          person.title.should == "Senorita"
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(:title => "Senorita", :ssn => "1") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          person.should be_new
        end

        it "sets the attributes" do
          person.title.should == "Senorita"
        end

        it "calls the block" do
          person.pets.should == true
        end
      end
    end
  end
end
