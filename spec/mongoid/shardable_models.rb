class SmMovie
  include Mongoid::Document

  field :year, type: Integer

  index year: 1
  shard_key :year
end

class SmTrailer
  include Mongoid::Document

  index year: 1
  shard_key 'year'
end

class SmActor
  include Mongoid::Document

  # This is not a usable shard configuration for the server.
  # We just have it for unit tests.
  shard_key age: 1, 'gender' => :hashed, 'hello' => :hashed
end

class SmAssistant
  include Mongoid::Document

  field :gender, type: String

  index gender: 1
  shard_key 'gender' => :hashed
end

class SmProducer
  include Mongoid::Document

  index age: 1, gender: 1
  shard_key({age: 1, gender: 'hashed'}, unique: true, numInitialChunks: 2)
end

class SmDirector
  include Mongoid::Document

  belongs_to :agency

  index age: 1
  shard_key :agency
end

class SmDriver
  include Mongoid::Document

  belongs_to :agency

  index age: 1, agency: 1
  shard_key age: 1, agency: :hashed
end

class SmNotSharded
  include Mongoid::Document
end

class SmReviewAuthor
  include Mongoid::Document
  embedded_in :review, class_name: "SmReview", touch: false
  field :name, type: String
end

class SmReview
  include Mongoid::Document

  embeds_one :author, class_name: "SmReviewAuthor"

  shard_key "author.name" => 1
end
