require "spec_helper"

describe Mongoid::Errors do

  describe Mongoid::Errors::DocumentNotFound do

    describe "#message" do

      context "default" do

        before do
          @error = Mongoid::Errors::DocumentNotFound.new(Person, "3")
        end

        it "contains document not found" do
          @error.message.should include("Document not found")
        end
      end
    end
  end

  describe Mongoid::Errors::InvalidOptions do

    describe "#message" do

      context "default" do

        before do
          @error = Mongoid::Errors::InvalidOptions.new(
            "embedded_in_must_have_inverse_of", {}
          )
        end

        it "returns the class name" do
          @error.message.should include("inverse_of")
        end
      end
    end
  end

  describe Mongoid::Errors::InvalidDatabase do

    describe "#message" do

      before do
        @error = Mongoid::Errors::InvalidDatabase.new("Test")
      end

      it "returns a message with the bad db object class" do
        @error.message.should include("String")
      end
    end
  end

  describe Mongoid::Errors::InvalidType do

    describe "#message" do

      before do
        @error = Mongoid::Errors::InvalidType.new(Array, "Test")
      end

      it "returns a message with the bad type and supplied value" do
        @error.message.should include("Array, but received a String")
      end
    end
  end

  describe Mongoid::Errors::UnsupportedVersion do

    describe "#message" do

      before do
        @version = Mongo::ServerVersion.new("1.2.4")
        @error = Mongoid::Errors::UnsupportedVersion.new(@version)
      end

      it "returns a message with the bad version and good version" do
        @error.message.should ==
          "MongoDB 1.2.4 not supported, please upgrade to #{Mongoid::MONGODB_VERSION}."
      end
    end
  end

  describe Mongoid::Errors::Validations do

    before do
      @errors = stub(:full_messages => [ "Error 1", "Error 2" ], :empty? => false)
      @document = stub(:errors => @errors)
      @error = Mongoid::Errors::Validations.new(@document)
    end
    
    describe "#message" do

      context "default" do

        it "contains the errors' full messages" do
          @error.message.should == "Validation failed - Error 1, Error 2."
        end
      end
    end
    
    describe "#document" do
      
      it "contains the a reference to the document" do
        @error.document.should == @document
      end
    end
  end

  describe Mongoid::Errors::InvalidCollection do

    describe "#message" do

      context "default" do

        before do
          @klass = Address
          @error = Mongoid::Errors::InvalidCollection.new(@klass)
        end

        it "contains class is not allowed" do
          @error.message.should include("Address is not allowed")
        end
      end
    end
  end

  describe Mongoid::Errors::InvalidField do

    describe "#message" do

      context "default" do

        before do
          @error = Mongoid::Errors::InvalidField.new("collection")
        end

        it "contains class is not allowed" do
          @error.message.should include("field named collection is not allowed")
        end
      end
    end
  end

  describe Mongoid::Errors::TooManyNestedAttributeRecords do
    describe "#message" do
      context "default" do
        before do
          @error = Mongoid::Errors::TooManyNestedAttributeRecords.new('Favorites', 5)
        end

        it "contains error message" do
          @error.message.should
            include("Accept Nested Attributes for Favorites is limited to 5 records.")
        end
      end
    end
  end
end
