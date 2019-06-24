# frozen_string_literal: true
# encoding: utf-8

class RootCategory
  include Mongoid::Document
  embeds_many :categories
end
