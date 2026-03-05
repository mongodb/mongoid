# frozen_string_literal: true
# rubocop:todo all

class Spacer
  include Mongoid::Document

  belongs_to :hole
end
