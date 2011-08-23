class Oscar
  include Mongoid::Document
  field :title, :type => String
  before_save :complain

  def complain
    false
  end
end
