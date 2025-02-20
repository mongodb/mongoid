# frozen_string_literal: true

class Cover
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String

  embedded_in :book
end
