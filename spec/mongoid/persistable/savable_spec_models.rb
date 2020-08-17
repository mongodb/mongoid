# frozen_string_literal: true
# encoding: utf-8

module SavableSpec
  class Truck
    include Mongoid::Document
    include Mongoid::Timestamps::Short

    embeds_many :crates, cascade_callbacks: true

    accepts_nested_attributes_for :crates

    field :capacity
  end

  class Crate
    include Mongoid::Document
    include Mongoid::Timestamps::Short

    embedded_in :truckable, polymorphic: true
    embeds_many :toys, cascade_callbacks: true

    accepts_nested_attributes_for :toys

    field :volume
  end

  class Toy
    include Mongoid::Document
    include Mongoid::Timestamps::Short

    field :type
  end
end
