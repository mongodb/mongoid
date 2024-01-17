# frozen_string_literal: true
# rubocop:todo all

class Updatable
  include Mongoid::Document

  field :updated_at, type: BSON::Timestamp
end
