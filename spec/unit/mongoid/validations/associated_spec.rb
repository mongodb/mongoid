require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  let(:person) do
    Person.new
  end

  describe "#validate_each" do

    let(:validator) do
      described_class.new(:attributes => person.attributes)
    end

    context "when the association is a one to one" do

      context "when the association is nil" do

        before do
          validator.validate_each(person, :name, nil)
        end

        it "adds no errors" do
          person.errors[:name].should be_empty
        end
      end

      context "when the association is valid" do

        let(:associated) do
          stub(:valid? => true)
        end

        before do
          associated.expects(:validated?).returns(false)
          validator.validate_each(person, :name, associated)
        end

        it "adds no errors" do
          person.errors[:name].should be_empty
        end
      end

      context "when the association is invalid" do

        let(:associated) do
          stub(:valid? => false)
        end

        before do
          associated.expects(:validated?).returns(false)
          validator.validate_each(person, :name, associated)
        end

        it "adds errors to the parent document" do
          person.errors[:name].should_not be_empty
        end

        it "translates the error in english" do
          person.errors[:name][0].should == "is invalid"
        end
      end
    end

    context "when the association is a one to many" do

      context "when the association is empty" do

        before do
          validator.validate_each(person, :addresses, [])
        end

        it "adds no errors" do
          person.errors[:addresses].should be_empty
        end
      end

      context "when the association has invalid documents" do

        let(:associated) do
          stub(:valid? => false)
        end

        before do
          associated.expects(:validated?).returns(false)
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds errors to the parent document" do
          person.errors[:addresses].should_not be_empty
        end
      end

      context "when the assocation has all valid documents" do

        let(:associated) do
          stub(:valid? => true)
        end

        before do
          associated.expects(:validated?).returns(false)
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds no errors" do
          person.errors[:addresses].should be_empty
        end
      end
    end
  end
end
