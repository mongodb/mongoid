# frozen_string_literal: true
# rubocop:todo all

class Version
  include Mongoid::Document
  field :number, type: Integer
  embedded_in :memorable, polymorphic: true
end
