require "spec_helper"

describe Mongoid::Validations::PresenceValidator do

  describe "#validate_each" do

    let(:product) do
      Product.new
    end

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
          product.errors[:name].should eq(["can't be blank"])
        end
      end

      context "when the value is empty" do

        before do
          validator.validate_each(product, :name, { "en" => "" })
        end

        it "adds errors" do
          product.errors[:name].should eq(["can't be blank"])
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
          product.errors[:name].should eq(["can't be blank"])
        end
      end
    end
  end

  context "when validating a localized field" do

    context "when any translation is blank" do

      let(:product) do
        Product.new
      end

      before do
        product.name_translations = { "de" => "" }
      end

      it "is not a valid document" do
        product.should_not be_valid
      end

      it "includes the proper errors" do
        product.valid?
        product.errors[:name].should_not be_empty
      end
    end

    context "when any translation is nil" do

      let(:product) do
        Product.new
      end

      before do
        product.name_translations = { "de" => nil }
      end

      it "is not a valid document" do
        product.should_not be_valid
      end

      it "includes the proper errors" do
        product.valid?
        product.errors[:name].should_not be_empty
      end
    end

    context "when the entire field is nil" do

      let(:product) do
        Product.new
      end

      before do
        product.name_translations = nil
      end

      it "is not a valid document" do
        product.should_not be_valid
      end

      it "includes the proper errors" do
        product.valid?
        product.errors[:name].should_not be_empty
      end
    end

    context "when the entire field is empty" do

      let(:product) do
        Product.new
      end

      before do
        product.name_translations = {}
      end

      it "is not a valid document" do
        product.should_not be_valid
      end

      it "includes the proper errors" do
        product.valid?
        product.errors[:name].should_not be_empty
      end
    end

    context "when the translations are present" do

      let(:product) do
        Product.new
      end

      before do
        product.name_translations = { "en" => "test" }
      end

      it "is a valid document" do
        product.should be_valid
      end
    end
  end

  context "when presence_of array attribute is updated and saved" do

    let(:updated_products) do
      [ "Laptop", "Tablet", "Smartphone", "Desktop" ]
    end

    let(:manufacturer) do
      Manufacturer.create!(:products => [ "Laptop", "Tablet" ])
    end

    before do
      manufacturer.products = updated_products
      manufacturer.save!
    end

    let(:reloaded) do
      Manufacturer.find(manufacturer.id)
    end

    it "persists the changes" do
      reloaded.products.should eq(updated_products)
    end
  end

  context "when an array attribute has been updated" do

    let(:updated_products) do
      [ "Laptop", "Tablet", "Smartphone", "Desktop" ]
    end

    let(:manufacturer) do
      Manufacturer.create!(:products => [ "Laptop", "Tablet" ])
    end

    context "when retrieved, flattened and iterated" do

      before do
        manufacturer.products = updated_products
        attrs = manufacturer.attributes
        [attrs].flatten.each { |attr| }
      end

      it "does not destroy the models change list" do
        manufacturer.changes.should_not be_empty
      end

      it "maintains the list of changes" do
        manufacturer.changes.should eq({
          "products" => [
            [ "Laptop", "Tablet" ],
            [ "Laptop", "Tablet", "Smartphone", "Desktop" ]
          ]
        })
      end
    end
  end
end
