class Question
  include Mongoid::Document
  field :content
  embedded_in :survey
  embeds_many :answers

  accepts_nested_attributes_for :answers, reject_if: ->(a){ a[:content].blank? }, allow_destroy: true
end
