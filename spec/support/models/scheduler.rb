# frozen_string_literal: true

class Scheduler
  include Mongoid::Document

  def strategy
    Strategy.new
  end
end
