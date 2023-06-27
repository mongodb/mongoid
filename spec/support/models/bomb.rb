# frozen_string_literal: true
# rubocop:todo all

class Bomb
  include Mongoid::Document
  has_one :explosion, dependent: :delete_all, autobuild: true
end
