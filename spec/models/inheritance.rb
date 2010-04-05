class Canvas
  include Mongoid::Document
  field :name
  embed_many :shapes
  embed_one :writer

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

  embedded_in :canvas, :inverse_of => :shapes

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

  embedded_in :canvas, :inverse_of => :writer

  def write; end
end

class HtmlWriter < Writer
  def write; end
end

class PdfWriter < Writer
  def write; end
end
