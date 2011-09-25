require "spec_helper"

describe Mongoid::Validations do

  let(:updated_products) do
    [ "Laptop", "Tablet", "Smartphone", "Desktop" ]
  end

  let(:manufacturer) do
    Manufacturer.create!(:products => [ "Laptop", "Tablet" ])
  end

  context "when presence_of array attribute is updated and saved" do

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
