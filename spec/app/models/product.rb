class Product
  include Mongoid::Document
  field :description, localize: true
  field :name, localize: true, default: "no translation"
  field :price, type: Integer
  field :brand_name
  field :stores, type: Array
  field :website, localize: true
  field :sku, as: :stock_keeping_unit
  field :tl, as: :tagline, localize: true
  alias_attribute :cost, :price

  validates :name, presence: true
  validates :website, format: { with: URI.regexp, allow_blank: true }

  embeds_one :seo, as: :seo_tags, cascade_callbacks: true, autobuild: true
end
