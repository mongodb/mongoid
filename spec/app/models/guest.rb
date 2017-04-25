class Guest
  include Mongoid::Document

  field :name, type: String, default: ''

  belongs_to :party, counter_cache: true, touch: true
end