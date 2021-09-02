# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Validatable::FormatValidator do

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
          expect(product.errors[:brand_name]).to be_empty
        end
      end

      context "when the value is invalid" do

        before do
          validator.validate_each(product, :brand_name, "123")
        end

        it "adds errors" do
          expect(product.errors[:brand_name]).to eq(["is invalid"])
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
          expect(product.errors[:website]).to be_empty
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
          expect(product.errors[:website]).to eq(["is invalid"])
        end
      end

      context "when the localized value is invalid" do

        before do
          validator.validate_each(product, :website, { "en" => "not_a_website" })
        end

        it "adds errors" do
          expect(product.errors[:website]).to eq(["is invalid"])
        end
      end
    end
  end
end
