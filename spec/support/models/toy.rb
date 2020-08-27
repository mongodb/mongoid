# frozen_string_literal: true
# encoding: utf-8

class Toy
  include Mongoid::Document

  embedded_in :crate

  field :name
end
