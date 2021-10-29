# frozen_string_literal: true

class Bolt
  include Mongoid::Document

  belongs_to :hole
end
