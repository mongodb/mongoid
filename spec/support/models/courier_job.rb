# frozen_string_literal: true
# rubocop:todo all

class CourierJob
  include Mongoid::Document
  embeds_one :drop_address, as: :addressable, autobuild: true, class_name: "ShipmentAddress"
end
