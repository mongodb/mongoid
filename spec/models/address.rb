class Address
  include Mongoid::Document
  field :address_type
  field :number, :type => Integer
  field :street
  field :city
  field :state
  field :post_code
  field :parent_title
  field :services, :type => Array
  key :street
  has_many :locations

  belongs_to :addressable, :inverse_of => :addresses do
    def extension
      "Testing"
    end
    def doctor?
      title == "Dr"
    end
  end

  named_scope :rodeo, where(:street => "Rodeo Dr")

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

  end
end