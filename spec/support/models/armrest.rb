# frozen_string_literal: true

class Armrest
  include Mongoid::Document

  embedded_in :seat

  field :side
end
