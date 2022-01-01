# frozen_string_literal: true

class Idnodef
  include Mongoid::Document

  field :_id, type: :string, overwrite: true
end
