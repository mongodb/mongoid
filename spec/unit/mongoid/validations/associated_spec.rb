require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  describe "#validate_each" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::AssociatedValidator.new(:attributes => @document.attributes) }

    context "when the association is a has one" do

      context "when the association is nil" do

        before do
          validator.validate_each(@document, :name, nil)
        end

        it "adds no errors" do
          @document.errors[:name].should be_empty
        end

      end

      context "when the association is valid" do

        before do
          @associated = stub(:valid? => true)
          validator.validate_each(@document, :name, @associated)
        end

        it "adds no errors" do
          @document.errors[:name].should be_empty
        end

      end

      context "when the association is invalid" do

        before do
          @associated = stub(:valid? => false)
          validator.validate_each(@document, :name, @associated)
        end

        it "adds errors to the parent document" do
          @document.errors[:name].should_not be_empty
        end

        it "translates the error in english" do
          @document.errors[:name][0].should == "is invalid"
        end

      end

    end

    context "when the association is a has many" do

      context "when the association is empty" do

        before do
          validator.validate_each(@document, :addresses, [])
        end

        it "adds no errors" do
          @document.errors[:addresses].should be_empty
        end

      end

      context "when the association has invalid documents" do

        before do
          @associated = stub(:valid? => false)
          validator.validate_each(@document, :addresses, [ @associated ])
        end

        it "adds errors to the parent document" do
          @document.errors[:addresses].should_not be_empty
        end

      end

      context "when the assocation has all valid documents" do

        before do
          @associated = stub(:valid? => true)
          validator.validate_each(@document, :addresses, [ @associated ])
        end

        it "adds no errors" do
          @document.errors[:addresses].should be_empty
        end

      end

    end

  end

end
