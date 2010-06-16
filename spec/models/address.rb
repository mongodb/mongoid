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
  embeds_many :locations

  embedded_in :addressable, :inverse_of => :addresses do
    def extension
      "Testing"
    end
    def doctor?
      title == "Dr"
    end
  end

  named_scope :rodeo, where(:street => "Rodeo Dr")

  validates_presence_of :street, :on => :update

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
