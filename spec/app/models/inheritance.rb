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

class Browser < Canvas
  field :version, :type => Integer
  def render; end
end

class Firefox < Browser
  field :user_agent
  def render; end
end

class Shape
  include Mongoid::Document
  field :x, :type => Integer, :default => 0
  field :y, :type => Integer, :default => 0

  embedded_in :canvas

  def render; end
end

class Square < Shape
  field :width, :type => Integer, :default => 0
  field :height, :type => Integer, :default => 0
end

class Circle < Shape
  field :radius, :type => Integer, :default => 0
end

class Writer
  include Mongoid::Document
  field :speed, :type => Integer, :default => 0

  embedded_in :canvas

  def write; end
end

class HtmlWriter < Writer
  def write; end
end

class PdfWriter < Writer
  def write; end
end

class Palette
  include Mongoid::Document
  embedded_in :canvas
  embeds_many :tools
end

class BigPalette < Palette
end

class Tool
  include Mongoid::Document
  embedded_in :palette

  accepts_nested_attributes_for :palette
end

class Pencil < Tool; end

class Eraser < Tool; end

########################################
# These are for references relationships
########################################
class ShippingContainer
  include Mongoid::Document
  has_many :vehicles

  accepts_nested_attributes_for :vehicles
end
class Vehicle
  include Mongoid::Document
  belongs_to :shipping_container
  belongs_to :driver

  accepts_nested_attributes_for :driver
  accepts_nested_attributes_for :shipping_containers
end
class Bed; end
class Car < Vehicle; end
class Truck < Vehicle
  embeds_one :bed
end

class Driver
  include Mongoid::Document

  has_one :vehicle
  accepts_nested_attributes_for :vehicle
end

class Learner < Driver
end
