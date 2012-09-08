class Server
  include Mongoid::Document
  field :name, type: String
  belongs_to :node
  embeds_many :filesystems, validate: false
  accepts_nested_attributes_for :filesystems
  validates :name, presence: { allow_blank: false }
end
