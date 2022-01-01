# frozen_string_literal: true

class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title, type: :string
  field :number, type: :string
  field :dob, type: :time
  embeds_many :names, as: :namable
  embeds_one :address
  belongs_to :game
  belongs_to :agency, touch: true, autobuild: true

  belongs_to :same_name, class_name: 'Band', inverse_of: :same_name

  has_and_belongs_to_many :accounts
  has_and_belongs_to_many :basics
end
