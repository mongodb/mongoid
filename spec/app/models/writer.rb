class Writer
  include Mongoid::Document
  field :speed, :type => Integer, :default => 0

  embedded_in :canvas

  def write; end
end
