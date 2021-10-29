# frozen_string_literal: true

class Sealer
  include Mongoid::Document

  belongs_to :hole
end
