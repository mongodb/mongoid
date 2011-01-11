class Answer
  include Mongoid::Document
  embedded_in :question
end
