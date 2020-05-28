# frozen_string_literal: true
# encoding: utf-8

class Bomb
  include Mongoid::Document
  has_one :explosion, dependent: :delete_all, autobuild: true
end
