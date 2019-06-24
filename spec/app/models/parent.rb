# frozen_string_literal: true
# encoding: utf-8

class Parent
  include Mongoid::Document
  embeds_many :sub_items
  embeds_one :first_child, class_name: "Child", as: :childable
end
