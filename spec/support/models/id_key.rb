# frozen_string_literal: true
# rubocop:todo all

class IdKey
  include Mongoid::Document
  field :key
  alias_method :id,  :key
  alias_method :id=, :key=
end
