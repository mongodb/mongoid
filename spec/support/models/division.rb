# frozen_string_literal: true

class Division
  include Mongoid::Document
  field :name, type: :string
  embedded_in :league
  before_destroy :update_parent

  def update_parent
    league.name = "Destroyed"
  end
end
