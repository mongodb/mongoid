class Party
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ''
  field :guests_count, type: Integer, default: 0

  has_many :guests, dependent: :destroy
  accepts_nested_attributes_for :guests, reject_if: :all_blank, allow_destroy: true
end