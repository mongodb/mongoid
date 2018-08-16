# frozen_string_literal: true

class Updatable
  include Mongoid::Document

  field :updated_at, type: BSON::Timestamp
end
