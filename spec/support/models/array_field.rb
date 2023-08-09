# frozen_string_literal: true
# rubocop:todo all

class ArrayField
  include Mongoid::Document

  field :af, type: Array
end
