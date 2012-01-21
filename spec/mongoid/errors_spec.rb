require "spec_helper"

describe Mongoid::Errors do

  describe Mongoid::Errors::DocumentNotFound do

    describe "attribute readers" do

      it 'exists for @identifiers' do
        Mongoid::Errors::DocumentNotFound.new(Person, "3").should respond_to :identifiers
      end

      it 'exists for @klass' do
        Mongoid::Errors::DocumentNotFound.new(Person, "3").should respond_to :klass
      end
    end

    describe "#message" do

      context "default" do

        let(:error) do
          Mongoid::Errors::DocumentNotFound.new(Person, "3")
        end

        it "contains document not found" do
          error.message.should include("Document not found")
        end
      end

      context "attributes search" do
         let(:error) do
           Mongoid::Errors::DocumentNotFound.new(Person, ssn: "123")
         end

         it "contains document not found" do
           error.message.should include("Document not found")
         end

         it "contains with attributes" do
           error.message.should include("with attributes")
         end
      end
    end
  end

  describe Mongoid::Errors::UnsavedDocument do

    let(:base) do
      Person.new
    end

    let(:document) do
      Post.new
    end

    let(:error) do
      Mongoid::Errors::UnsavedDocument.new(base, document)
    end

    describe "#message" do

      it "returns that create can not be called" do
        error.message.should include(
          "You cannot call create or create! through a relation"
        )
      end
    end
  end

  describe Mongoid::Errors::InvalidOptions do

    describe "#message" do

      context "default" do

        let(:error) do
          Mongoid::Errors::InvalidOptions.new(
            :name, :invalid, [ :valid ]
          )
        end

        it "returns the class name" do
          error.message.should include("Invalid option")
        end
      end
    end
  end

  describe Mongoid::Errors::InvalidDatabase do

    describe "#message" do

      let(:error) do
        Mongoid::Errors::InvalidDatabase.new("Test")
      end

      it "returns a message with the bad db object class" do
        error.message.should include("String")
      end
    end
  end

  describe Mongoid::Errors::InvalidType do

    describe "#message" do

      let(:error) do
        Mongoid::Errors::InvalidType.new(Array, "Test")
      end

      it "returns a message with the bad type and supplied value" do
        error.message.should include("Array, but received a String")
      end
    end
  end

  describe Mongoid::Errors::UnsupportedVersion do

    describe "#message" do

      let(:version) do
        Mongo::ServerVersion.new("1.2.4")
      end

      let(:error) do
        Mongoid::Errors::UnsupportedVersion.new(version)
      end

      it "returns a message with the bad version and good version" do
        error.message.should eq(
          "MongoDB 1.2.4 not supported, please upgrade to #{Mongoid::MONGODB_VERSION}."
        )
      end
    end
  end

  describe Mongoid::Errors::Validations do

    let(:errors) do
      stub(:full_messages => [ "Error 1", "Error 2" ], :empty? => false)
    end

    let(:document) do
      stub(:errors => errors)
    end

    let(:error) do
      Mongoid::Errors::Validations.new(document)
    end

    describe "#message" do

      context "default" do

        it "contains the errors' full messages" do
          error.message.should eq("Validation failed - Error 1, Error 2.")
        end
      end
    end

    describe "#document" do

      it "contains the a reference to the document" do
        error.document.should eq(document)
      end
    end
  end

  describe Mongoid::Errors::InvalidCollection do

    describe "#message" do

      context "default" do

        let(:klass) do
          Address
        end

        let(:error) do
          Mongoid::Errors::InvalidCollection.new(klass)
        end

        it "contains class is not allowed" do
          error.message.should include("Address is not allowed")
        end
      end
    end
  end

  describe Mongoid::Errors::InvalidField do

    describe "#message" do

      context "default" do

        let(:error) do
          Mongoid::Errors::InvalidField.new("collection")
        end

        it "contains class is not allowed" do
          error.message.should include("field named collection is not allowed")
        end
      end
    end
  end

  describe Mongoid::Errors::TooManyNestedAttributeRecords do

    describe "#message" do

      context "default" do

        let(:error) do
          Mongoid::Errors::TooManyNestedAttributeRecords.new('Favorites', 5)
        end

        it "contains error message" do
          error.message.should
            include("Accept Nested Attributes for Favorites is limited to 5 records.")
        end
      end
    end
  end
end
