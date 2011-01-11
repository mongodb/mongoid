class Page
  include Mongoid::Document
  embedded_in :quiz
  embeds_many :page_questions
end
