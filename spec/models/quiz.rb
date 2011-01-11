class Quiz
  include Mongoid::Document
  embeds_many :pages
end
