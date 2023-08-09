# frozen_string_literal: true
# rubocop:todo all

class Threadlocker
  include Mongoid::Document

  belongs_to :hole
end
