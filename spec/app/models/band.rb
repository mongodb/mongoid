class Band
  include Mongoid::Document
  field :name, :type => String

  embeds_many :records, :cascade_callbacks => true
  embeds_one :label, :cascade_callbacks => true
end
