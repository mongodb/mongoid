# frozen_string_literal: true

class Server
  include Mongoid::Document
  field :name, type: :string
  field :after, type: :boolean, default: false
  belongs_to :node
  embeds_many :filesystems, validate: false
  accepts_nested_attributes_for :filesystems
  validates :name, presence: { allow_blank: false }

  after_create do |server|
    server.update_attribute(:after, !after)
  end
end
