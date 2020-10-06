# frozen_string_literal: true
# encoding: utf-8

class Idnodef
  include Mongoid::Document

  field :_id, type: String, overwrite: true
end
