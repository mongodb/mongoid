class Message
  include Mongoid::Document

  field :body, type: String

  embedded_in :person
  has_and_belongs_to_many :receviers, class_name: "Person", inverse_of: nil
end
