# frozen_string_literal: true

class ValidationCallback
  include Mongoid::Document
  field :history, type: Array, default: []
  validate do
    self.history << :validate
  end

  before_validation { self.history << :before_validation }
  after_validation { self.history << :after_validation }
end
