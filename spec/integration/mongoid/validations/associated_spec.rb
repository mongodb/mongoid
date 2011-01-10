require "spec_helper"

describe Mongoid::Validations::AssociatedValidator do

  describe "#valid?" do

    context "when validating associated on both sides" do

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
  end
end
