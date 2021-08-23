# frozen_string_literal: true

class Toy
  include Mongoid::Document

  embedded_in :crate

  field :name
end
