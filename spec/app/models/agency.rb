# frozen_string_literal: true

class Agency
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  has_many :agents, validate: false
end
