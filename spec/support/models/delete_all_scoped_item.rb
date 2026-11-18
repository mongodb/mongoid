# frozen_string_literal: true

class DeleteAllScopedItem
  include Mongoid::Document

  field :state, type: String

  belongs_to :account, class_name: 'DeleteAllAccount', inverse_of: :scoped_items

  default_scope -> { where(:state.in => %w[draft open]) }
end
