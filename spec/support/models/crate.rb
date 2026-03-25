# frozen_string_literal: true

class Crate
  include Mongoid::Document

  embedded_in :vehicle
  embeds_many :toys

  accepts_nested_attributes_for :toys

  field :volume
end
