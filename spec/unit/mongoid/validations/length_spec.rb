require "spec_helper"

describe Mongoid::Validations::LengthValidator do

  describe "#validate_each" do

    let(:product) do
      Product.new
    end

    context "when the field is not localized" do

      let(:validator) do
        described_class.new(:attributes => [:brand_name], :in => 1..5)
      end

      context "when the value is valid" do

        before do
          validator.validate_each(product, :brand_name, "Apple")
        end

        it "adds no errors" do
          product.errors[:brand_name].should be_empty
        end
      end

      context "when the value is invalid" do

        before do
          validator.validate_each(product, :brand_name, "123456")
        end

        it "adds errors" do
          product.errors[:brand_name].should eq(
            ["is too long (maximum is 5 characters)"]
          )
        end
      end
    end

    context "when the field is localized" do

      let(:validator) do
        described_class.new(:attributes => [:website], :in => 1..5)
      end

      context "when the localized value is valid" do

        before do
          validator.validate_each(product, :website, { "en" => "12345" })
        end

        it "adds no errors" do
          product.errors[:website].should be_empty
        end
      end

      context "when one of the localized values is invalid" do

        before do
          validator.validate_each(
            product,
            :website, { "en" => "12345", "fr" => "123456" }
          )
        end

        it "adds errors" do
          product.errors[:website].should eq(
            ["is too long (maximum is 5 characters)"]
          )
        end
      end

      context "when the localized value is invalid" do

        before do
          validator.validate_each(product, :website, { "en" => "123456" })
        end

        it "adds errors" do
          product.errors[:website].should eq(
            ["is too long (maximum is 5 characters)"]
          )
        end
      end
    end
  end
end
