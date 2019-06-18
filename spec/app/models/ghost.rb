# frozen_string_literal: true
# encoding: utf-8

class Ghost
  include Mongoid::Document

  field :name, type: String

  belongs_to :movie, autosave: true
end
