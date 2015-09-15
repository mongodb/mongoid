class Note
  include Mongoid::Document
  field :text, type: String
  field :saved, type: Mongoid::Boolean, default: false
  embedded_in :noteable, polymorphic: true

  after_save :update_saved

  scope :permanent, ->{ where(saved: true) }

  def update_saved
    self.saved = true
  end

  embedded_in :page
  field :message, :type => String
end
