require "spec_helper"

describe Mongoid::Validations::PresenceValidator do

  let(:product) do
    Product.new
  end

  describe "#validate_each" do

    let(:validator) do
      described_class.new(:attributes => product.attributes)
    end

    context "when the field is not localized" do

      context "when the value is valid" do

        before do
          validator.validate_each(product, :brand_name, "Apple")
        end

        it "adds no errors" do
          product.errors[:brand_name].should be_empty
        end
      end

      context "when the value is nil" do

        before do
          validator.validate_each(product, :brand_name, nil)
        end

        it "adds errors" do
          product.errors[:brand_name].should eq(["can't be blank"])
        end
      end

      context "when the value is empty" do

        before do
          validator.validate_each(product, :brand_name, "")
        end

        it "adds errors" do
          product.errors[:brand_name].should eq(["can't be blank"])
        end
      end
    end

    context "when the field is localized" do

      context "when the value is valid" do

        before do
          validator.validate_each(product, :name, { "en" => "iPod Nano 8GB - Black" })
        end

        it "adds no errors" do
          product.errors[:name].should be_empty
        end
      end

      context "when the value is nil" do

        before do
          validator.validate_each(product, :name, nil)
        end

        it "adds errors" do
          product.errors[:name].should eq(["can't be blank"])
        end
      end

      context "when the localized value is nil" do

        before do
          validator.validate_each(product, :name, { "en" => nil })
        end

        it "adds errors" do
          product.errors[:name].should eq(["can't be blank in en"])
        end
      end

      context "when the value is empty" do

        before do
          validator.validate_each(product, :name, { "en" => "" })
        end

        it "adds errors" do
          product.errors[:name].should eq(["can't be blank in en"])
        end
      end

      context "when the value is empty for a language" do

        before do
          validator.validate_each(
            product,
            :name,
            { "en" => "iPod Nano 8GB - Black", "de" => "" }
          )
        end

        it "adds errors" do
          product.errors[:name].should eq(["can't be blank in de"])
        end
      end

      context "when the value is empty for several language" do
        before do
          validator.validate_each(
            product,
            :name,
            { "en" => "", "de" => "" }
          )
        end

        it "adds en errors" do
          product.errors[:name].should include("can't be blank in en")
        end

        it "adds de errors" do
          product.errors[:name].should include("can't be blank in de")
        end
      end
    end
  end
end
