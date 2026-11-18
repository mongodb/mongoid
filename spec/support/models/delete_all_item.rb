# frozen_string_literal: true

class DeleteAllItem
  include Mongoid::Document

  field :state, type: String

  belongs_to :account, class_name: 'DeleteAllAccount', inverse_of: :items
end
