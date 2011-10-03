class Track
  include Mongoid::Document
  field :name, :type => String

  embedded_in :record
end
