# frozen_string_literal: true
# encoding: utf-8

class Code
  include Mongoid::Document
  field :name, type: String
  embedded_in :address
  embeds_one :deepest
end

class Deepest
  include Mongoid::Document
  embedded_in :code
end
