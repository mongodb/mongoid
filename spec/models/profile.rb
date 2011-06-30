class Profile
  include Mongoid::Document
  field :name, type: String
  shard_key :name
end
