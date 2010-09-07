class Address
  include Mongoid::Document

  attr_accessor :mode

  field :address_type
  field :number, :type => Integer
  field :street
  field :city
  field :state
  field :post_code
  field :parent_title
  field :services, :type => Array
  field :latlng, :type => Array
  key :street
  embeds_many :locations

  embedded_in :addressable, :polymorphic => true do
    def extension
      "Testing"
    end
    def doctor?
      title == "Dr"
    end
  end

  named_scope :rodeo, where(:street => "Rodeo Dr") do
    def mansion?
      all? { |address| address.street == "Rodeo Dr" }
    end
  end

  validates_presence_of :street, :on => :update
  validates_format_of :street, :with => /\D/, :allow_nil => true

  def set_parent=(set = false)
    self.parent_title = addressable.title if set
  end

  class << self
    def california
      where(:state => "CA")
    end

    def homes
      where(:address_type => "Home")
    end

    def streets
      all.map(&:street)
    end
  end
end
