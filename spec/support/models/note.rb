# frozen_string_literal: true

class Note
  include Mongoid::Document
  field :text, type: :string
  field :saved, type: :boolean, default: false
  embedded_in :noteable, polymorphic: true

  after_save :update_saved

  scope :permanent, ->{ where(saved: true) }

  def update_saved
    self.saved = true
  end

  embedded_in :page
  field :message, :type => String
end
