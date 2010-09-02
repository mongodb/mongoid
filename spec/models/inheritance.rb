class Canvas
  include Mongoid::Document
  field :name
  embeds_many :shapes
  embeds_one :writer
  embeds_one :palette

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

class Tool
  include Mongoid::Document
  embedded_in :palette
end

class Pencil < Tool; end

class Eraser < Tool; end
