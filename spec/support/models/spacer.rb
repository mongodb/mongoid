# frozen_string_literal: true

class Spacer
  include Mongoid::Document

  belongs_to :hole
end
