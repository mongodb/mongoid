# frozen_string_literal: true
# encoding: utf-8

class Shelf
  include Mongoid::Document
  field :level, type: Integer
  recursively_embeds_one
end
