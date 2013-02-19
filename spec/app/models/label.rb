class Label
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short

  field :name, type: String
  field :after_create_called, type: Boolean, default: false
  field :after_save_called, type: Boolean, default: false
  field :after_update_called, type: Boolean, default: false
  field :after_validation_called, type: Boolean, default: false

  embedded_in :artist
  embedded_in :band

  after_create :after_create_stub
  after_save :after_save_stub
  after_update :after_update_stub
  after_validation :after_validation_stub
  before_validation :cleanup

  def after_create_stub
    self.after_create_called = true
  end

  def after_save_stub
    self.after_save_called = true
  end

  def after_update_stub
    self.after_update_called = true
  end

  def after_validation_stub
    self.after_validation_called = true
  end

  private
  def cleanup
    self.name = self.name.downcase.capitalize
  end
end
