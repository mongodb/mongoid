class Answer
  include Mongoid::Document
  embedded_in :question, :inverse_of => :answers
end
