# frozen_string_literal: true
# rubocop:todo all

class Idnodef
  include Mongoid::Document

  field :_id, type: String, overwrite: true
end
