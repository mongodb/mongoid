class Server
  include Mongoid::Document
  field :name, type: String
  belongs_to :node
  validates :name, presence: { allow_blank: false }
end
