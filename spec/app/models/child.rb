# frozen_string_literal: true
# encoding: utf-8

class Child
  include Mongoid::Document
  embedded_in :parent, inverse_of: :childable, polymorphic: true
end
