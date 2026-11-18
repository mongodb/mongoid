# frozen_string_literal: true

class DeleteAllAccount
  include Mongoid::Document

  has_many :items, class_name: 'DeleteAllItem', foreign_key: :account_id, inverse_of: :account,
                   scope: -> { where(:state.in => %w[draft open]) }
  has_many :scoped_items, class_name: 'DeleteAllScopedItem', foreign_key: :account_id, inverse_of: :account
  has_and_belongs_to_many :tags, class_name: 'DeleteAllTag', inverse_of: nil
end
