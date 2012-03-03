require "spec_helper"

describe Mongoid::Validations::FormatValidator do

  describe "#validate_each" do

    let(:product) do
      Product.new
    end

    context "when the field is not localized" do

      let(:validator) do
        described_class.new(attributes: [:brand_name], with: /\A[a-z]*\z/i)
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
          validator.validate_each(product, :brand_name, "123")
        end

        it "adds errors" do
          product.errors[:brand_name].should eq(["is invalid"])
        end
      end
    end

    context "when the field is localized" do

      let(:validator) do
        described_class.new(attributes: [:website], with: URI.regexp)
      end

      context "when the localized value is valid" do

        before do
          validator.validate_each(product, :website, { "en" => "http://www.apple.com" })
        end

        it "adds no errors" do
          product.errors[:website].should be_empty
        end
      end

      context "when one of the localized values is invalid" do

        before do
          validator.validate_each(
            product,
            :website, { "en" => "http://www.apple.com", "fr" => "not_a_website" }
          )
        end

        it "adds errors" do
          product.errors[:website].should eq(["is invalid"])
        end
      end

      context "when the localized value is invalid" do

        before do
          validator.validate_each(product, :website, { "en" => "not_a_website" })
        end

        it "adds errors" do
          product.errors[:website].should eq(["is invalid"])
        end
      end
    end
  end
end
