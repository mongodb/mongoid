require 'spec_helper'

describe 'valdations for array attributes' do
  let (:updated_products) { ["Laptop", "Tablet", "Smartphone", "Desktop"] }

  let (:manufacturer) do
    Manufacturer.create! :products => ["Laptop", "Tablet"]
  end

  context "when presence_of array attribute is updated and saved" do
    before do
      manufacturer.products = updated_products
      manufacturer.save!
    end

    it "should persist the changes" do
      reloaded = Manufacturer.find(manufacturer.id)
      reloaded.products.should == updated_products
    end
  end

  context "when an array attribute has been updated and it is retrieved, flattened and iterated" do
    let(:changes) do
      manufacturer.products = updated_products
      manufacturer.changes
    end

    before do
      attrs = manufacturer.attributes
      [attrs].flatten.each { |attr| } # do nothing. this mimics ActiveModel::Errors#add_on_blank, line 223
    end

    it "should not destroy the models change list" do
      manufacturer.changes.should_not be_empty
    end

    it "should maintain the list of changes" do
      manufacturer.changes.should == changes
    end
  end

end
