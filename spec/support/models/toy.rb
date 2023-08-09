# frozen_string_literal: true
# rubocop:todo all

class Toy
  include Mongoid::Document

  embedded_in :crate

  field :name
end
