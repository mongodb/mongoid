# frozen_string_literal: true
# rubocop:todo all

class Translation
  include Mongoid::Document
  field :language
  embedded_in :name
end
