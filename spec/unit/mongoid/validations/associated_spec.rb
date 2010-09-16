require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  describe "#validate_each" do

    let(:person) do
      Person.new
    end

    let(:validator) do
      Mongoid::Validations::AssociatedValidator.new(
        :attributes => person.attributes
      )
    end

    context "when the association is a has one" do

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
          validator.validate_each(person, :name, associated)
        end

        it "adds no errors" do
          person.errors[:name].should be_empty
        end
      end

      context "when the association is invalid" do

        let!(:associated) do
          Address.new
        end

        before do
          associated.expects(:valid?).at_least(1).returns(false)
          associated.errors.add(:street, "is required")
          associated.errors.add(:city, "is required")
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds errors to the parent document" do
          person.errors[:addresses].should_not be_empty
        end

        it "translates the error in english" do
          person.errors[:addresses][0].should ==
            [ "Street is required", "City is required" ]
        end
      end
    end

    context "when the association is a embeds many" do

      context "when the association is empty" do

        before do
          validator.validate_each(person, :addresses, [])
        end

        it "adds no errors" do
          person.errors[:addresses].should be_empty
        end
      end

      context "when the association has invalid documents" do


        let(:errors) do
          stub(:full_messages => [ "is invalid" ])
        end

        let(:associated) do
          stub(:valid? => false, :errors => errors)
        end

        before do
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
          validator.validate_each(person, :addresses, [ associated ])
        end

        it "adds no errors" do
          person.errors[:addresses].should be_empty
        end
      end
    end
  end
end
