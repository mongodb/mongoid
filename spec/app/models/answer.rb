class Answer
  include Mongoid::Document
  embedded_in :question

  field :position, type: Integer
end
