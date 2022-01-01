# frozen_string_literal: true

class ArrayField
  include Mongoid::Document

  field :af, type: :array
end
