# frozen_string_literal: true
# rubocop:todo all

class Folder
  include Mongoid::Document

  field :name, type: String
  has_many :folder_items

end
