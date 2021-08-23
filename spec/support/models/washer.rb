# frozen_string_literal: true

class Washer
  include Mongoid::Document

  belongs_to :hole
end
