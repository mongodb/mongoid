# frozen_string_literal: true
# rubocop:todo all

class Thing
  include Mongoid::Document
  before_destroy :dont_do_it
  embedded_in :actor

  def dont_do_it
    throw(:abort)
  end
end
