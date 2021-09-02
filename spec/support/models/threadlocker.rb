# frozen_string_literal: true

class Threadlocker
  include Mongoid::Document

  belongs_to :hole
end
