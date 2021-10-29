# frozen_string_literal: true

class Seat
  include Mongoid::Document

  embedded_in :vehicle

  field :rating, type: Integer

  embeds_many :armrests

  before_create :set_rating
  before_update :update_rating

  private

  def set_rating
    self.rating ||= 100
  end

  def update_rating
    self.rating += 1
  end
end
