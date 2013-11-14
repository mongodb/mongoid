class Oscar
  include Mongoid::Document
  field :title, type: String
  field :destroy_after_save, type: Mongoid::Boolean, default: false
  before_save :complain

  def complain
    if destroy_after_save?
      destroy
      true
    else
      false
    end
  end
end
