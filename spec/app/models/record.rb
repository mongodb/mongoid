# frozen_string_literal: true

class Record
  include Mongoid::Document
  field :name, type: String
  field :producers, type: Array

  field :before_create_called, type: Mongoid::Boolean, default: false
  field :before_save_called, type: Mongoid::Boolean, default: false
  field :before_update_called, type: Mongoid::Boolean, default: false
  field :before_validation_called, type: Mongoid::Boolean, default: false
  field :before_destroy_called, type: Mongoid::Boolean, default: false

  embedded_in :band
  embeds_many :tracks, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false

  before_create :before_create_stub
  before_save :before_save_stub
  before_update :before_update_stub
  before_validation :before_validation_stub
  before_destroy :before_destroy_stub

  after_destroy :access_band

  def before_create_stub
    self.before_create_called = true
  end

  def before_save_stub
    self.before_save_called = true
  end

  def before_update_stub
    self.before_update_called = true
  end

  def before_validation_stub
    self.before_validation_called = true
  end

  def before_destroy_stub
    self.before_destroy_called = true
  end

  def access_band
    band.name
  end

  def dont_call_me_twice
  end

  validate { dont_call_me_twice }
end
