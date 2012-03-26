class Note
  include Mongoid::Document
  field :text, type: String
  field :saved, type: Boolean, default: false
  embedded_in :noteable, polymorphic: true

  after_save :update_saved

  def update_saved
    self.saved = true
  end
end
