class Canvas
  include Mongoid::Document
  field :name
  embeds_many :shapes
  embeds_one :writer
  embeds_one :palette

  field :foo, type: String, default: ->{ "original" }

  has_many :comments, as: :commentable

  accepts_nested_attributes_for :shapes
  accepts_nested_attributes_for :writer

  def render
    shapes.each { |shape| render }
  end

  class Test < Canvas

    field :foo, type: String, overwrite: true, default: ->{ "overridden" }
  end
end

require "app/models/browser"
