# frozen_string_literal: true

class Translation
  include Mongoid::Document
  field :language
  embedded_in :name
end
