# frozen_string_literal: true

class Profile
  include Mongoid::Document
  field :name, type: String

  embeds_one :profile_image

  shard_key :name
end

class ProfileImage
  include Mongoid::Document
  field :url, type: String

  embedded_in :profile
end
