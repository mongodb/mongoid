# frozen_string_literal: true

class Oscar
  include Mongoid::Document
  field :title, type: :string
  field :destroy_after_save, type: :boolean, default: false
  before_save :complain

  def complain
    if destroy_after_save?
      destroy
    else
      throw(:abort)
    end
  end
end
