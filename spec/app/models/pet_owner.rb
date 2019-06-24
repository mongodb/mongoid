# frozen_string_literal: true
# encoding: utf-8

class PetOwner
  include Mongoid::Document
  field :title
  embeds_one :pet, cascade_callbacks: true
  embeds_one :address, as: :addressable
end
