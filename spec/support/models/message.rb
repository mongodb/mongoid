# frozen_string_literal: true

class Message
  include Mongoid::Document

  field :body, type: :string
  field :priority, type: :integer

  embedded_in :person
  has_and_belongs_to_many :receivers, class_name: "Person", inverse_of: nil

  has_one :post, as: :posteable
end
