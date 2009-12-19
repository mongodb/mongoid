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
          @error = Mongoid::Errors::InvalidOptions.new
        end

        it "returns the class name" do
          @error.message.should == @error.class.name
        end

      end

    end

  end

  describe Mongoid::Errors::InvalidDatabase do

    describe "#message" do

      context "default" do

        before do
          @error = Mongoid::Errors::InvalidDatabase.new
        end

        it "returns the class name" do
          @error.message.should == @error.class.name
        end

      end

    end

  end

  describe Mongoid::Errors::Validations do

    describe "#message" do

      context "default" do

        before do
          @errors = stub(:full_messages => "Testing")
          @error = Mongoid::Errors::Validations.new(@errors)
        end

        it "contains the errors' full messages" do
          @error.message.should include("Testing")
        end

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

end
