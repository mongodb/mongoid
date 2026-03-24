# frozen_string_literal: true

class Idnodef
  include Mongoid::Document

  field :_id, type: String, overwrite: true
end
