# frozen_string_literal: true

class Service
  include Mongoid::Document
  field :sid
  field :before_destroy_called, type: Mongoid::Boolean, default: false
  field :after_destroy_called, type: Mongoid::Boolean, default: false
  field :after_initialize_called, type: Mongoid::Boolean, default: false
  embedded_in :person
  belongs_to :target, class_name: "User"
  validates_numericality_of :sid

  before_destroy do |doc|
    doc.before_destroy_called = true
  end

  after_destroy do |doc|
    doc.after_destroy_called = true
  end

  after_initialize do |doc|
    doc.after_initialize_called = true
  end
end
