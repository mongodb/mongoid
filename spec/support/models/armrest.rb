# frozen_string_literal: true
# rubocop:todo all

class Armrest
  include Mongoid::Document

  embedded_in :seat

  field :side
end
