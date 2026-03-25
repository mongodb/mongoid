# frozen_string_literal: true

class IdKey
  include Mongoid::Document

  field :key
  alias id key
  alias id= key=
end
