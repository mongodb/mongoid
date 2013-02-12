class Princess
  include Mongoid::Document
  field :primary_color
  def color
    primary_color.to_s
  end
  validates_presence_of :color
end
