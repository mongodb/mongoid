# frozen_string_literal: true
# rubocop:todo all

class Sealer
  include Mongoid::Document

  belongs_to :hole
end
