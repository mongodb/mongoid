class Person
  include Mongoid::Document
  include Mongoid::Timestamps

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
  field :ssn
  field :owner_id, :accessible => false, :type => Integer
  field :security_code

  index :age
  index :addresses
  index :dob
  index :name
  index :title
  index :ssn, :unique => true

  attr_reader :rescored

  attr_protected :security_code

  embeds_many :favorites
  embeds_many :videos
  embeds_many :phone_numbers, :class_name => "Phone"
  embeds_many :addresses do
    def extension
      "Testing"
    end
    def find_by_street(street)
      @target.select { |doc| doc.street == street }
    end
  end

  embeds_one :pet, :class_name => "Animal"
  embeds_one :name do
    def extension
      "Testing"
    end
    def dawkins?
      first_name == "Richard" && last_name == "Dawkins"
    end
  end

  accepts_nested_attributes_for :addresses, :reject_if => lambda { |attrs| attrs["street"].blank? }
  accepts_nested_attributes_for :name, :update_only => true
  accepts_nested_attributes_for :pet
  accepts_nested_attributes_for :favorites, :allow_destroy => true, :limit => 5

  references_one :game do
    def extension
      "Testing"
    end
  end

  references_many :posts do
    def extension
      "Testing"
    end
  end
  references_many :paranoid_posts
  references_many :preferences, :stored_as => :array, :inverse_of => :people

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
