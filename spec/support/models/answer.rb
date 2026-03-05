# frozen_string_literal: true
# rubocop:todo all

class Answer
  include Mongoid::Document
  embedded_in :question

  field :position, type: Integer
end
