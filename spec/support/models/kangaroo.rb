# frozen_string_literal: true
# encoding: utf-8

class Kangaroo
  include Mongoid::Document
  embeds_one :baby
end
