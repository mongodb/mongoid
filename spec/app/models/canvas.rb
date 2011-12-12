class Canvas
  include Mongoid::Document
  field :name
  embeds_many :shapes
  embeds_one :writer
  embeds_one :palette

  accepts_nested_attributes_for :shapes
  accepts_nested_attributes_for :writer

  def render
    shapes.each { |shape| render }
  end
end
