# frozen_string_literal: true
# encoding: utf-8

class Tree
  include Mongoid::Document

  field :name
  field :evergreen, type: Mongoid::Boolean

  scope :verdant, ->{ where(evergreen: true) }
  default_scope ->{ asc(:name) }
end
