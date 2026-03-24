# frozen_string_literal: true

class Hole
  include Mongoid::Document

  has_one :bolt, dependent: :destroy
  has_one :threadlocker, dependent: :delete_all
  has_one :sealer, dependent: :restrict_with_exception
  has_many :nuts, dependent: :destroy
  has_many :washers, dependent: :delete_all
  has_many :spacers, dependent: :restrict_with_exception
end
