# frozen_string_literal: true

class Quiz
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :name, type: :string
  field :topic, type: :string
  embeds_many :pages
end
