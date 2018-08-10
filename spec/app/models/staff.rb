# frozen_string_literal: true

class Staff
  include Mongoid::Document

  embedded_in :company

  field :age, type: Integer
end
