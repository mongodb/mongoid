class Dokument
  include Mongoid::Document
  include Mongoid::Timestamps
  embeds_many :addresses, as: :addressable, validate: false
end
