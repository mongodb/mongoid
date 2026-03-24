# frozen_string_literal: true

class ValidationCallback
  include Mongoid::Document

  field :history, type: Array, default: []
  validate do
    history << :validate
  end

  before_validation { history << :before_validation }
  after_validation { history << :after_validation }
end
