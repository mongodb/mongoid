# frozen_string_literal: true

class Description
  include Mongoid::Document

  field :details

  belongs_to :user
  belongs_to :updater, class_name: 'User'

  validates :user, associated: true
  validates :details, presence: true
end
