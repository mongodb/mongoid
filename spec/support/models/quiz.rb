# frozen_string_literal: true
# rubocop:todo all

class Quiz
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :name, type: String
  field :topic, type: String
  embeds_many :pages
end
