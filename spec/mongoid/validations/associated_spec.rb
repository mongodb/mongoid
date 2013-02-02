require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  describe "#valid?" do

    context "when validating associated on both sides" do

      context "when the documents are valid" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description) do
          Description.new(details: "testing")
        end

        before do
          user.descriptions << description
        end

        it "only validates the parent once" do
          user.should be_valid
        end

        it "only validates the child once" do
          description.should be_valid
        end
      end

      context "when the documents are not valid" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description) do
          Description.new
        end

        before do
          user.descriptions << description
        end

        it "only validates the parent once" do
          user.should_not be_valid
        end

        it "adds the errors from the relation" do
          user.valid?
          user.errors[:descriptions].should_not be_nil
        end

        it "only validates the child once" do
          description.should_not be_valid
        end
      end
    end
  end

  describe "#validate_each" do

    let(:person) do
      Person.new
    end

    let(:validator) do
      described_class.new(attributes: person.attributes)
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
          stub(valid?: true)
        end

        before do
          associated.should_receive(:validated?).and_return(false)
          validator.validate_each(person, :name, associated)
        end

        it "adds no errors" do
          person.errors[:name].should be_empty
        end
      end

      context "when the association is invalid" do

        let(:associated) do
          stub(valid?: false)
        end

        before do
          associated.should_receive(:validated?).and_return(false)
          validator.validate_each(person, :name, associated)
        end

        it "adds errors to the parent document" do
          person.errors[:name].should_not be_empty
        end

        it "translates the error in english" do
          person.errors[:name][0].should eq("is invalid")
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
          stub(valid?: false)
        end

        before do
          associated.should_receive(:validated?).and_return(false)
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds errors to the parent document" do
          person.errors[:addresses].should_not be_empty
        end
      end

      context "when the assocation has all valid documents" do

        let(:associated) do
          stub(valid?: true)
        end

        before do
          associated.should_receive(:validated?).and_return(false)
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds no errors" do
          person.errors[:addresses].should be_empty
        end
      end
    end
  end

  context "when describing validation on the instance level" do

    let!(:dictionary) do
      Dictionary.create!(name: "en")
    end

    let(:validators) do
      dictionary.validates_associated :words
    end

    it "adds the validation only to the instance" do
      validators.should eq([ described_class ])
    end
  end
end
