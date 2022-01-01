# frozen_string_literal: true

class FolderItem

  include Mongoid::Document

  belongs_to :folder
  field :name, type: :string

  validates :name, uniqueness: {scope: :folder_id}
end
