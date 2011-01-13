class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :mode

  field :title
  field :terms, :type => Boolean
  field :pets, :type => Boolean, :default => false
  field :age, :type => Integer, :default => 100
  field :dob, :type => Date
  field :mixed_drink, :type => MixedDrink
  field :employer_id
  field :lunch_time, :type => Time
  field :aliases, :type => Array
  field :map, :type => Hash
  field :score, :type => Integer
  field :blood_alcohol_content, :type => Float, :default => lambda{ 0.0 }
  field :last_drink_taken_at, :type => Date, :default => lambda { 1.day.ago.in_time_zone("Alaska") }
  field :ssn
  field :owner_id, :type => Integer
  field :security_code
  field :reading, :type => Object
  field :bson_id, :type => BSON::ObjectId

  index :age
  index :addresses
  index :dob
  index :name
  index :title
  index :ssn, :unique => true

  attr_reader :rescored

  attr_protected :security_code, :owner_id

  embeds_many :favorites, :order => :title.desc, :validate => false, :inverse_of => :perp
  embeds_many :videos, :order => [[ :title, :asc ]],  :validate => false
  embeds_many :phone_numbers, :class_name => "Phone", :validate => false
  embeds_many :addresses, :as => :addressable, :validate => false do
    def extension
      "Testing"
    end
    def find_by_street(street)
      @target.select { |doc| doc.street == street }
    end
  end
  embeds_many :address_components, :validate => false

  embeds_one :pet, :class_name => "Animal", :validate => false
  embeds_one :name, :as => :namable, :validate => false do
    def extension
      "Testing"
    end
    def dawkins?
      first_name == "Richard" && last_name == "Dawkins"
    end
  end

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :name, :update_only => true
  accepts_nested_attributes_for :pet, :allow_destroy => true
  accepts_nested_attributes_for :game, :allow_destroy => true
  accepts_nested_attributes_for :favorites, :allow_destroy => true, :limit => 5
  accepts_nested_attributes_for :posts
  accepts_nested_attributes_for :preferences

  references_one :game, :dependent => :destroy, :validate => false do
    def extension
      "Testing"
    end
  end

  references_many \
    :posts,
    :dependent => :delete,
    :validate => :false,
    :default_order => :created_at.desc do
    def extension
      "Testing"
    end
  end
  references_many :paranoid_posts, :validate => false
  references_and_referenced_in_many \
    :preferences,
    :index => true,
    :dependent => :nullify
  references_and_referenced_in_many :user_accounts
  references_and_referenced_in_many :houses

  references_many :drugs, :autosave => true
  references_one :account, :autosave => true

  def score_with_rescoring=(score)
    @rescored = score.to_i + 20
    self.score_without_rescoring = score
  end

  alias_method_chain :score=, :rescoring

  def update_addresses
    addresses.each do |address|
      address.street = "Updated Address"
    end
  end

  def employer=(emp)
    self.employer_id = emp.id
  end

  class << self
    def accepted
      criteria.where(:terms => true)
    end
    def knight
      criteria.where(:title => "Sir")
    end
    def old
      criteria.where(:age => { "$gt" => 50 })
    end
  end

end

class Doctor < Person
  field :specialty
end
