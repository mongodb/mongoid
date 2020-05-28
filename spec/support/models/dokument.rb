# frozen_string_literal: true
# encoding: utf-8

class Dokument
  include Mongoid::Document
  include Mongoid::Timestamps
  embeds_many :addresses, as: :addressable, validate: false
  field :title
end
