require "spec_helper"

class MyAddress
  include Mongoid::Document
  embedded_in :addressable, polymorphic: true

  field :street, type: String
end

class ShipmentAddress < MyAddress
  include Mongoid::Document
end

class Office
  include Mongoid::Document

  embeds_one :address, as: :addressable, autobuild: true, class_name: "ShipmentAddress"
end

class Building
  include Mongoid::Document
  embeds_one :drop_address, as: :addressable, autobuild: true, class_name: "ShipmentAddress"
end

describe Mongoid::Relations::Embedded::One do
  it "should be able to use office address in building, since it is of the same class" do
    building = Building.create!({
      drop_address: ShipmentAddress.new({street: "123 fake street"})
    })

    building.reload
    expect(building.drop_address.street).to eq "123 fake street"

    office =  Office.create!({
      address: ShipmentAddress.new({street: "other address"})
    })

    building.update_attribute(:drop_address, office.address)
    expect(building.drop_address.street).to eq "other address"

    building = Building.find(building.id)
    expect(building.drop_address.street).to eq "other address"
  end
end
