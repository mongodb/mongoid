# frozen_string_literal: true

class Acolyte
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :status
  field :name

  embeds_many :versions, as: :memorable
  belongs_to :church

  default_scope ->{ asc(:name) }
  scope :active, ->{ where(status: "active") }
  scope :named, ->{ where(:name.exists => true) }

  def callback_test?
    name == "callback-test"
  end
end
