# frozen_string_literal: true
# encoding: utf-8

class Oscar
  include Mongoid::Document
  field :title, type: String
  field :destroy_after_save, type: Mongoid::Boolean, default: false
  before_save :complain

  def complain
    if destroy_after_save?
      destroy
    else
      throw(:abort)
    end
  end
end
