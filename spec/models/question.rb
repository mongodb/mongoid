class Question
  include Mongoid::Document
  field :content
  embedded_in :survey, :inverse_of => :questions
  embeds_many :answers
  
  accepts_nested_attributes_for :answers, :reject_if => lambda { |a| a[:content].blank? }, :allow_destroy => true
end