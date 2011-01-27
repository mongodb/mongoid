class Quiz
  include Mongoid::Document
  field :topic
  embeds_many :pages
end
