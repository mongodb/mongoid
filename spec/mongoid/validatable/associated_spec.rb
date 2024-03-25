# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Validatable::AssociatedValidator do

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
          expect(user).to be_valid
        end

        it "only validates the child once" do
          expect(description).to be_valid
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
          expect(user).to_not be_valid
        end

        it "adds the errors from the relation" do
          user.valid?
          expect(user.errors[:descriptions]).to_not be_nil
        end

        it "only validates the child once" do
          expect(description).to_not be_valid
        end
      end

      context "when the documents are flagged for destroy" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description) do
          Description.new
        end

        before do
          description.flagged_for_destroy = true
          user.descriptions << description
        end

        it "does not run validation on them" do
          expect(user).to be_valid
        end

      end

    end
  end

  describe "#validate" do

    let(:person) do
      Person.new
    end

    let(:validator) do
      described_class.new(attributes: person.relations.keys)
    end

    context "when the association is a one to one" do

      context "when the association is nil" do

        before do
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:name]).to be_empty
        end
      end

      context "when the association is valid" do
        before do
          person.name = Name.new(first_name: 'A', last_name: 'B')
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:name]).to be_empty
        end
      end

      context "when the association is invalid" do

        before do
          person.name = Name.new(first_name: 'Jamis', last_name: 'Buck')
          validator.validate(person)
        end

        it "adds errors to the parent document" do
          expect(person.errors[:name]).to_not be_empty
        end

        it "translates the error in english" do
          expect(person.errors[:name][0]).to eq("is invalid")
        end
      end
    end

    context "when the association is a one to many" do

      context "when the association is empty" do

        before do
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:addresses]).to be_empty
        end
      end

      context "when the association has invalid documents" do

        before do
          person.addresses << Address.new(street: '123')
          validator.validate(person)
        end

        it "adds errors to the parent document" do
          expect(person.errors[:addresses]).to_not be_empty
        end
      end

      context "when the association has all valid documents" do

        before do
          person.addresses << Address.new(street: '123 First St')
          person.addresses << Address.new(street: '456 Second St')
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:addresses]).to be_empty
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
      expect(validators).to eq([ described_class ])
    end
  end
end
