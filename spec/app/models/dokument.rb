class Dokument
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  embeds_many :addresses, as: :addressable, validate: false
end
