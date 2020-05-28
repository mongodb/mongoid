# frozen_string_literal: true
# encoding: utf-8

class FolderItem

  include Mongoid::Document

  belongs_to :folder
  field :name, type: String

  validates :name, uniqueness: {scope: :folder_id}
end
