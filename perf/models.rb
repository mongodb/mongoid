# frozen_string_literal: true

class Person
  include Mongoid::Document

  field :birth_date, type: Date
  field :title, type: String

  embeds_one :name, validate: false
  embeds_many :addresses, validate: false

  has_many :posts, validate: false
  has_one :game, validate: false
  has_and_belongs_to_many :preferences, validate: false

  index preference_ids: 1
end

class Name
  include Mongoid::Document

  field :given, type: String
  field :family, type: String
  field :middle, type: String
  embedded_in :person
end

class Address
  include Mongoid::Document

  field :street, type: String
  field :city, type: String
  field :state, type: String
  field :post_code, type: String
  field :address_type, type: String
  embedded_in :person
end

class Post
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  belongs_to :person
  has_many :alerts

  index person_id: 1
end

class Game
  include Mongoid::Document

  field :name, type: String
  belongs_to :person

  index person_id: 1
end

class Preference
  include Mongoid::Document

  field :name, type: String
  has_and_belongs_to_many :people, validate: false

  index person_ids: 1
end

class Account
  include Mongoid::Document

  field :name, type: String
  belongs_to :person
  has_one :comment

  index person_id: 1
end

class Comment
  include Mongoid::Document

  field :title, type: String
  belongs_to :account

  index account_id: 1
end

class Alert
  include Mongoid::Document

  field :message, type: String
  belongs_to :post

  index post_id: 1
end

# PR #6158 scenarios -------------------------------------------------------

# Subclass association: Speaker inherits from Gadget and owns the :cables
# association; Gadget itself does not define it.
class Gadget
  include Mongoid::Document

  field :name, type: String
end

class Speaker < Gadget
  has_many :cables
end

class Cable
  include Mongoid::Document

  field :label, type: String
  belongs_to :speaker
  index speaker_id: 1
end

# Peripheral is the referenced target for both embedded scenarios below.
class Peripheral
  include Mongoid::Document

  field :name, type: String
end

# Embedded reference (embeds_one): Computer embeds one Port which
# holds a belongs_to reference to a Peripheral.
class Computer
  include Mongoid::Document

  field :name, type: String
  embeds_one :port
end

class Port
  include Mongoid::Document

  field :label, type: String
  embedded_in :computer
  belongs_to :peripheral
end

# Embedded reference (embeds_many): Rack embeds multiple Slots, each
# holding a belongs_to reference to a Peripheral.
class Rack
  include Mongoid::Document

  field :name, type: String
  embeds_many :slots
end

class Slot
  include Mongoid::Document

  field :label, type: String
  embedded_in :rack
  belongs_to :peripheral
end

# Polymorphic belongs_to: Cartridge can belong to either a Printer or a
# Scanner via a single polymorphic association.
class Printer
  include Mongoid::Document

  field :model, type: String
end

class Scanner
  include Mongoid::Document

  field :model, type: String
end

class Cartridge
  include Mongoid::Document

  belongs_to :hardware, polymorphic: true
  index({ hardware_type: 1, hardware_id: 1 })
end
