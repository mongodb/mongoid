class Template
  include Mongoid::Document
  field :active, type: Boolean, default: false
  validates :active, presence: true
end
