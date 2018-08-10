# frozen_string_literal: true

class Division
  include Mongoid::Document
  field :name, type: String
  embedded_in :league
  before_destroy :update_parent

  def update_parent
    league.name = "Destroyed"
  end
end
