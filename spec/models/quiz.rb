class Quiz
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :topic
  embeds_many :pages
end
