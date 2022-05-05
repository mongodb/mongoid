# frozen_string_literal: true

class Code
  include Mongoid::Document
  field :name, type: :string
  embedded_in :address
  embeds_one :deepest
end

class Deepest
  include Mongoid::Document
  embedded_in :code

  field :array, type: Array
end
