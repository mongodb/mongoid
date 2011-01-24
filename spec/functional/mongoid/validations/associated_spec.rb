require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  describe "#valid?" do

    context "when validating associated on both sides" do

      context "when the documents are valid" do

        let(:user) do
          User.new(:name => "test")
        end

        let(:description) do
          Description.new(:details => "testing")
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
          User.new(:name => "test")
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
end
