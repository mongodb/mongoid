class Server
  include Mongoid::Document
  field :name, type: String
  field :after, type: Mongoid::Boolean, default: false
  belongs_to :node
  embeds_many :filesystems, validate: false
  accepts_nested_attributes_for :filesystems
  validates :name, presence: { allow_blank: false }

  after_create do |server|
    server.update_attribute(:after, !after)
  end
end
