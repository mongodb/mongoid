# frozen_string_literal: true
# encoding: utf-8

class Circus
  include Mongoid::Document

  field :name

  embeds_many :animals
end
