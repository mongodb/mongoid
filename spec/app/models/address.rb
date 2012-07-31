class Address
  include Mongoid::Document

  field :_id, type: String, default: ->{ street.try(:parameterize) }

  attr_accessor :mode

  field :address_type
  field :number, type: Integer
  field :street
  field :city
  field :state
  field :post_code
  field :parent_title
  field :services, type: Array
  field :latlng, type: Array
  field :map, type: Hash
  field :move_in, type: DateTime

  embeds_many :locations, validate: false
  embeds_one :code, validate: false
  embeds_one :target, as: :targetable, validate: false

  embedded_in :addressable, polymorphic: true do
    def extension
      "Testing"
    end
    def doctor?
      title == "Dr"
    end
  end

  accepts_nested_attributes_for :locations, :code, :target

  belongs_to :account

  scope :without_postcode, where(postcode: nil)
  scope :rodeo, where(street: "Rodeo Dr") do
    def mansion?
      all? { |address| address.street == "Rodeo Dr" }
    end
  end

  validates_presence_of :street, on: :update
  validates_format_of :street, with: /\D/, allow_nil: true

  def set_parent=(set = false)
    self.parent_title = addressable.title if set
  end

  def <=>(other)
    street <=> other.street
  end

  class << self
    def california
      where(state: "CA")
    end

    def homes
      where(address_type: "Home")
    end

    def streets
      all.map(&:street)
    end
  end
end
