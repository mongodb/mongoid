# frozen_string_literal: true

class Person
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  attr_accessor :mode

  class_attribute :somebody_elses_important_class_options
  self.somebody_elses_important_class_options = { keep_me_around: true }

  field :username, default: -> { "arthurnn#{rand(0..10)}" }
  field :title
  field :terms, type: Mongoid::Boolean
  field :pets, type: Mongoid::Boolean, default: false
  field :age, type: Integer, default: "100"
  field :dob, type: Date
  field :employer_id
  field :lunch_time, type: Time
  field :aliases, type: Array
  field :map, type: Hash
  field :map_with_default, type: Hash, default: {}
  field :score, type: Integer
  field :blood_alcohol_content, type: Float, default: ->{ 0.0 }
  field :last_drink_taken_at, type: Date, default: ->{ 1.day.ago.in_time_zone("Alaska") }
  field :ssn
  field :owner_id, type: Integer
  field :security_code
  field :reading, type: Object
  field :bson_id, type: BSON::ObjectId
  field :pattern, type: Regexp
  field :override_me, type: Integer
  field :at, as: :aliased_timestamp, type: Time
  field :t, as: :test, type: String
  field :i, as: :inte, type: Integer
  field :a, as: :array, type: Array
  field :desc, localize: true
  field :localized_translations, localize: true
  field :test_array, type: Array
  field :overridden_setter, type: String
  field :arrays, type: Array
  field :range, type: Range
  field :species, type: Symbol
  field :posts_count, type: Integer, default: 0

  index age: 1
  index addresses: 1
  index dob: 1
  index name: 1
  index title: 1

  attr_reader :rescored

  embeds_many :favorites, order: :title.desc, inverse_of: :perp, validate: false
  embeds_many :videos, order: [[ :title, :asc ]], validate: false
  embeds_many :phone_numbers, class_name: "Phone", validate: false
  embeds_many :phones, store_as: :mobile_phones, validate: false
  embeds_many :addresses, as: :addressable, validate: false do
    def extension
      "Testing"
    end
    def find_by_street(street)
      where(street: street).first
    end
  end

  embeds_many :address_components, validate: false
  embeds_many :services, cascade_callbacks: true, validate: false
  embeds_many :symptoms, validate: false
  embeds_many :appointments, validate: false
  embeds_many :messages, validate: false

  embeds_one :passport, autobuild: true, store_as: :pass, validate: false
  embeds_one :pet, class_name: "Animal", validate: false
  embeds_one :name, as: :namable, validate: false do
    def extension
      "Testing"
    end
    def dawkins?
      first_name == "Richard" && last_name == "Dawkins"
    end
  end
  embeds_one :quiz, validate: false

  # Must have dependent: :destroy
  has_one :game, dependent: :destroy, validate: false do
    def extension
      "Testing"
    end
  end

  has_many \
    :posts,
    dependent: :delete_all,
    validate: false do
    def extension
      "Testing"
    end
  end
  has_many :ordered_posts, order: :rating.desc, validate: false
  has_and_belongs_to_many \
    :preferences,
    index: true,
    dependent: :nullify,
    validate: false
  has_and_belongs_to_many :user_accounts, validate: false
  has_and_belongs_to_many :houses, validate: false
  has_and_belongs_to_many :ordered_preferences, order: :value.desc, validate: false

  has_many :drugs, validate: false
  # Must not have dependent: :destroy
  has_one :account, validate: false
  has_one :cat, dependent: :nullify, validate: false, primary_key: :username
  has_one :book, autobuild: true, validate: false
  has_one :home, dependent: :delete_all, validate: false

  has_and_belongs_to_many \
    :administrated_events,
    class_name: 'Event',
    inverse_of: :administrators,
    dependent:  :nullify,
    validate: false

  belongs_to :mother, class_name: 'Person'
  has_many :children, class_name: 'Person'

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :name, update_only: true
  accepts_nested_attributes_for :pet, allow_destroy: true
  accepts_nested_attributes_for :game, allow_destroy: true
  accepts_nested_attributes_for :favorites, allow_destroy: true, limit: 5
  accepts_nested_attributes_for :posts
  accepts_nested_attributes_for :preferences
  accepts_nested_attributes_for :quiz
  accepts_nested_attributes_for :services, allow_destroy: true

  scope :minor, ->{ where(:age.lt => 18) }
  scope :without_ssn, ->{ without(:ssn) }
  scope :search, ->(query){ any_of({ title: query }) }

  def self.older_than(age:)
    where(:age.gt => age)
  end

  def score_with_rescoring=(score)
    @rescored = score.to_i + 20
    self.score_without_rescoring = score
  end

  alias_method :score_without_rescoring=, :score=
  alias_method :score=, :score_with_rescoring=

  def update_addresses
    addresses.each do |address|
      address.street = "Updated Address"
    end
  end

  def employer=(emp)
    self.employer_id = emp.id
  end

  def set_addresses=(addresses)
    self.addresses = addresses
  end

  def override_me
    read_attribute(:override_me).to_s
  end

  def overridden_setter=(value)
    @override_called = true
    super(value)
  end

  class << self
    def accepted
      scoped.where(terms: true)
    end
    def knight
      scoped.where(title: "Sir")
    end
    def old
      scoped.where(age: { "$gt" => 50 })
    end
  end

  def reject_if_city_is_empty(attrs)
    attrs[:city].blank?
  end

  def reject_if_name_is_blank(attrs)
    attrs[:first_name].blank?
  end

  def foo
    'i_am_foo'
  end

  def preference_names=(names)
    names.split(",").each do |name|
      preference = Preference.where(name: name).first
      if preference
        self.preferences << preference
      else
        preferences.build(name: name)
      end
    end
  end

  def set_on_map_with_default=(value)
    self.map_with_default["key"] = value
  end

  def set_personal_data(ssn:, age:)
    self.ssn = ssn
    self.age = age
  end

  reset_callbacks(:validate)
  reset_callbacks(:create)
  reset_callbacks(:save)
  reset_callbacks(:destroy)

  private

  def secret_name
    "secret"
  end
end

require "support/models/doctor"
