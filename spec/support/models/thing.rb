# frozen_string_literal: true
# encoding: utf-8

class Thing
  include Mongoid::Document
  before_destroy :dont_do_it
  embedded_in :actor

  def dont_do_it
    throw(:abort)
  end
end
