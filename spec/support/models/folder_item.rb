# frozen_string_literal: true
# rubocop:todo all

class FolderItem

  include Mongoid::Document

  belongs_to :folder
  field :name, type: String

  validates :name, uniqueness: {scope: :folder_id}
end
